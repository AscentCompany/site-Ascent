#!/bin/bash
# =============================================================
# start-logs.sh — Garante que o ascent-logs esteja rodando.
#
# Pensado para ser chamado pelo cron (ex.: a cada 5 minutos):
#   */5 * * * * /bin/bash /caminho/site-Ascent/start-logs.sh >/dev/null 2>&1
#
# Se o container estiver parado, ele é iniciado;
# se não existir, é criado.
# =============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE="$SCRIPT_DIR/.env"
CONTAINER="ascent-logs"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERRO: arquivo .env não encontrado em $SCRIPT_DIR"
  exit 1
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
  docker start "$CONTAINER" >/dev/null
else
  echo ">> Criando container $CONTAINER na rede $NETWORK..."
  docker run -d \
    --name "$CONTAINER" \
    --network "$NETWORK" \
    --restart no \
    -p 8080:8080 \
    --env-file "$ENV_FILE" \
    -e DB_HOST=mysql \
    -e DB_PORT=3306 \
    lucasveneroso/ascent:ascent-logs >/dev/null
fi
