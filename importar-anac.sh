#!/bin/bash
# =============================================================
# importar-anac.sh — Executa a importação ANAC uma vez.
#
# Pode ser chamado manualmente ou pelo start.sh. É seguro repetir:
#   - só uma execução por vez (flock);
#   - arquivos já importados são pulados;
#   - arquivo interrompido é limpo e reprocessado (sem duplicar);
#   - o container NÃO usa --rm, então o exit code e o log ficam para análise.
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

# Uma importação por vez. Se já houver uma rodando, sai sem derrubar nada.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo ">> Já existe uma importação em andamento. Nada a fazer."
  exit 0
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = "true" ]; then
  echo ">> $CONTAINER já está rodando. Nada a fazer."
  exit 0
fi

# Remove apenas o container residual (parado) de uma execução anterior.
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

# Descobre a rede em que o MySQL está conectado.
MYSQL_ID="$(docker ps -q --filter "name=ascent-mysql" | head -n1)"
NETWORK=""
if [ -n "$MYSQL_ID" ]; then
  NETWORK="$(docker inspect -f '{{range $nome, $_ := .NetworkSettings.Networks}}{{$nome}}{{end}}' "$MYSQL_ID" 2>/dev/null || true)"
fi
if [ -z "$NETWORK" ]; then
  NETWORK="ascent_ascent"
fi

# Em EC2, usa as credenciais temporárias da IAM Role. Fora dela, usa o .env.
ENV_EXTRA=()
if curl -s -m 2 http://169.254.169.254/latest/meta-data/ 2>/dev/null | grep -q 'ami-id'; then
  ROLE_NAME="$(curl -s -m 2 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null)"
  if [ -n "$ROLE_NAME" ]; then
    CREDS="$(curl -s -m 2 "http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME")"
    EC2_KEY_ID="$(echo "$CREDS" | grep -o '"AccessKeyId" : "[^"]*"' | cut -d'"' -f4)"
    EC2_SECRET="$(echo "$CREDS" | grep -o '"SecretAccessKey" : "[^"]*"' | cut -d'"' -f4)"
    EC2_TOKEN="$(echo "$CREDS" | grep -o '"Token" : "[^"]*"' | cut -d'"' -f4)"
    if [ -n "$EC2_KEY_ID" ]; then
      ENV_EXTRA=(-e AWS_ACCESS_KEY_ID="$EC2_KEY_ID" -e AWS_SECRET_ACCESS_KEY="$EC2_SECRET" -e AWS_SESSION_TOKEN="$EC2_TOKEN")
      echo ">> Credenciais da IAM Role obtidas via metadata da EC2."
    fi
  fi
fi

echo ">> Iniciando importação ($IMAGEM). Log: $LOG_FILE"
echo ">> Rede: $NETWORK | DB_HOST=mysql"

docker run --name "$CONTAINER" \
  --network "$NETWORK" \
  --env-file "$ENV_FILE" \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  "${ENV_EXTRA[@]}" \
  "$IMAGEM" 2>&1 | tee -a "$LOG_FILE"

CODIGO=${PIPESTATUS[0]}
echo ">> Importação encerrada com código $CODIGO."
exit "$CODIGO"
