#!/bin/bash
# =============================================================
# apache-po.sh — Lê os Excel ANAC (Apache POI) e grava no MySQL.
#
# Independente do start.sh. Pré-requisitos:
#   1. Stack no ar: ./start.sh
#   2. Dados base:  ./inserir-dados.sh  (já chamado pelo start.sh)
#   3. Na EC2: LabRole com acesso ao bucket S3
#      Fora da EC2: AWS_* válidas no .env (session token não pode estar expirado)
#
# Seguro repetir:
#   - uma execução por vez (flock);
#   - arquivos já importados são pulados;
#   - parcial interrompido é limpo e reprocessado.
# =============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGEM="${APACHEPOI_IMAGE:-lucasveneroso/ascent:ascent-apachepoi-s3}"
CONTAINER="ascent-apachepoi"
ENV_FILE="$SCRIPT_DIR/.env"
LOG_FILE="$SCRIPT_DIR/importacao.log"
LOCK_FILE="$SCRIPT_DIR/.importacao.lock"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERRO: arquivo .env não encontrado em $SCRIPT_DIR"
  exit 1
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo ">> Já existe uma importação em andamento. Nada a fazer."
  exit 0
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = "true" ]; then
  echo ">> $CONTAINER já está rodando. Nada a fazer."
  exit 0
fi

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

if ! docker image inspect "$IMAGEM" >/dev/null 2>&1; then
  echo ">> Baixando imagem $IMAGEM ..."
  docker pull "$IMAGEM" || {
    echo "ERRO: não foi possível baixar $IMAGEM"
    exit 1
  }
fi

MYSQL_ID="$(docker ps -q --filter "name=ascent-mysql" | head -n1)"
NETWORK=""
if [ -n "$MYSQL_ID" ]; then
  NETWORK="$(docker inspect -f '{{range $nome, $_ := .NetworkSettings.Networks}}{{$nome}}{{end}}' "$MYSQL_ID" 2>/dev/null || true)"
fi
if [ -z "$NETWORK" ]; then
  NETWORK="ascent_ascent"
fi

if [ -z "$MYSQL_ID" ]; then
  echo "ERRO: ascent-mysql não está rodando. Execute ./start.sh antes."
  exit 1
fi

# Na EC2 com LabRole: usa credenciais temporárias da role e IGNORA
# AWS_* do .env (tokens de lab expirados geram "400 Bad Request" no S3).
ENV_EXTRA=(-e DB_HOST=mysql -e DB_PORT=3306)
if curl -s -m 2 http://169.254.169.254/latest/meta-data/ 2>/dev/null | grep -q 'ami-id'; then
  ROLE_NAME="$(curl -s -m 2 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null || true)"
  if [ -n "$ROLE_NAME" ]; then
    CREDS="$(curl -s -m 2 "http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME")"
    EC2_KEY_ID="$(echo "$CREDS" | grep -o '"AccessKeyId" : "[^"]*"' | cut -d'"' -f4)"
    EC2_SECRET="$(echo "$CREDS" | grep -o '"SecretAccessKey" : "[^"]*"' | cut -d'"' -f4)"
    EC2_TOKEN="$(echo "$CREDS" | grep -o '"Token" : "[^"]*"' | cut -d'"' -f4)"
    if [ -n "$EC2_KEY_ID" ]; then
      ENV_EXTRA+=(
        -e AWS_ACCESS_KEY_ID="$EC2_KEY_ID"
        -e AWS_SECRET_ACCESS_KEY="$EC2_SECRET"
        -e AWS_SESSION_TOKEN="$EC2_TOKEN"
      )
      echo ">> Credenciais da IAM Role ($ROLE_NAME) obtidas via metadata da EC2."
    else
      echo ">> AVISO: LabRole detectada, mas não foi possível ler as chaves."
    fi
  else
    echo ">> AVISO: EC2 sem IAM Role. Usando AWS_* do .env (precisam estar válidas)."
  fi
else
  echo ">> Ambiente local: usando AWS_* do .env."
fi

echo ">> Iniciando importação ($IMAGEM). Log: $LOG_FILE"
echo ">> Rede: $NETWORK | DB_HOST=mysql"

docker run --name "$CONTAINER" \
  --network "$NETWORK" \
  --env-file "$ENV_FILE" \
  "${ENV_EXTRA[@]}" \
  "$IMAGEM" 2>&1 | tee -a "$LOG_FILE"

CODIGO=${PIPESTATUS[0]}
echo ">> Importação encerrada com código $CODIGO."
if [ "$CODIGO" -ne 0 ]; then
  echo ">> Se o erro for S3 400/ExpiredToken: atualize AWS_* no .env ou anexe LabRole na EC2."
fi
exit "$CODIGO"
