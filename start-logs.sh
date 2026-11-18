#!/bin/bash
# =============================================================
# start-logs.sh — Garante que o ascent-logs esteja rodando.
#
# Chamado no boot (cron @reboot) ou manualmente. É seguro repetir:
#   - uma execução por vez (flock);
#   - se o container existe e está parado, inicia;
#   - se não existe (ou sumiu no meio), cria com restart: unless-stopped.
# =============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE="$SCRIPT_DIR/.env"
CONTAINER="ascent-logs"
IMAGEM="lucasveneroso/ascent:ascent-logs"
LOCK_FILE="$SCRIPT_DIR/.start-logs.lock"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERRO: arquivo .env não encontrado em $SCRIPT_DIR"
  exit 1
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  exit 0
fi

# Já está rodando? Não faz nada.
if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = "true" ]; then
  exit 0
fi

# Descobre a rede em que o MySQL está conectado.
MYSQL_ID="$(docker ps -q --filter "name=ascent-mysql" | head -n1)"
NETWORK=""
if [ -n "$MYSQL_ID" ]; then
  NETWORK="$(docker inspect -f '{{range $nome, $_ := .NetworkSettings.Networks}}{{$nome}}{{end}}' "$MYSQL_ID" 2>/dev/null || true)"
fi
if [ -z "$NETWORK" ]; then
  NETWORK="ascent_ascent"
fi

if docker inspect "$CONTAINER" >/dev/null 2>&1; then
  echo ">> Iniciando container $CONTAINER..."
  # Se o container sumir entre o inspect e o start, recria abaixo.
  if ! docker start "$CONTAINER" >/dev/null 2>&1; then
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  fi
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" != "true" ]; then
  if ! docker image inspect "$IMAGEM" >/dev/null 2>&1; then
    docker pull "$IMAGEM" >/dev/null 2>&1 || true
  fi
  if docker image inspect "$IMAGEM" >/dev/null 2>&1; then
    echo ">> Criando container $CONTAINER na rede $NETWORK..."
    docker run -d \
      --name "$CONTAINER" \
      --network "$NETWORK" \
      --restart unless-stopped \
      -p 8080:8080 \
      --env-file "$ENV_FILE" \
      -e DB_HOST=mysql \
      -e DB_PORT=3306 \
      "$IMAGEM" >/dev/null || {
        echo ">> AVISO: não foi possível criar $CONTAINER."
        exit 0
      }
  else
    echo ">> AVISO: imagem $IMAGEM indisponível. ascent-logs não iniciado."
    exit 0
  fi
fi
