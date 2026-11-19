#!/bin/bash
# =============================================================
# inserir-dados.sh — Aplica schema + dados iniciais no MySQL.
#
# Por que o MySQL sobe "sem dados"?
# O MySQL só executa /docker-entrypoint-initdb.d na PRIMEIRA
# inicialização (quando /var/lib/mysql está vazio). Com o volume
# persistente /dados/mysql já existente, o ascent.sql do compose
# NÃO roda de novo. Este script corrige isso a qualquer momento.
#
# Uso:
#   ./inserir-dados.sh
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE="$SCRIPT_DIR/.env"
SCHEMA_SQL="$SCRIPT_DIR/database/ascent.sql"
CONTAINER="ascent-mysql"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERRO: .env não encontrado em $SCRIPT_DIR"
  exit 1
fi

# Lê só as chaves do banco (evita quebrar com tokens AWS no .env).
ler_env() {
  local chave="$1" padrao="$2" valor
  valor="$(grep -E "^${chave}=" "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r' || true)"
  if [ -z "$valor" ]; then
    echo "$padrao"
  else
    echo "$valor"
  fi
}

DB_USER="$(ler_env DB_USER admin)"
DB_PASSWORD="$(ler_env DB_PASSWORD admin)"
DB_DATABASE="$(ler_env DB_DATABASE ascent)"

if [ ! -f "$SCHEMA_SQL" ]; then
  echo "ERRO: arquivo SQL não encontrado: $SCHEMA_SQL"
  exit 1
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" != "true" ]; then
  echo "ERRO: container $CONTAINER não está rodando. Suba a stack com ./start.sh primeiro."
  exit 1
fi

echo "=== 1. Aguardando MySQL aceitar conexões ==="
for _ in $(seq 1 60); do
  if docker exec "$CONTAINER" mysqladmin ping -h localhost -u"$DB_USER" -p"$DB_PASSWORD" --silent >/dev/null 2>&1; then
    echo ">> MySQL pronto."
    break
  fi
  sleep 2
done

if ! docker exec "$CONTAINER" mysqladmin ping -h localhost -u"$DB_USER" -p"$DB_PASSWORD" --silent >/dev/null 2>&1; then
  echo "ERRO: MySQL não respondeu a tempo."
  exit 1
fi

echo "=== 2. Aplicando schema e dados iniciais (ascent.sql - idempotente) ==="
docker exec -i "$CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" < "$SCHEMA_SQL"
echo ">> Schema e dados iniciais aplicados com sucesso (sem apagar dados existentes)."

echo "=== 3. Conferência ==="
docker exec "$CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -N -e "
  SELECT 'companhia' AS tabela, COUNT(*) AS total FROM \`$DB_DATABASE\`.companhia
  UNION ALL SELECT 'cargo', COUNT(*) FROM \`$DB_DATABASE\`.cargo
  UNION ALL SELECT 'usuario', COUNT(*) FROM \`$DB_DATABASE\`.usuario
  UNION ALL SELECT 'permissao', COUNT(*) FROM \`$DB_DATABASE\`.permissao
  UNION ALL SELECT 'funcionalidade', COUNT(*) FROM \`$DB_DATABASE\`.funcionalidade
  UNION ALL SELECT 'voo', COUNT(*) FROM \`$DB_DATABASE\`.voo;
" 2>/dev/null | column -t 2>/dev/null || docker exec "$CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -e "
  SELECT 'companhia' AS tabela, COUNT(*) AS total FROM \`$DB_DATABASE\`.companhia
  UNION ALL SELECT 'cargo', COUNT(*) FROM \`$DB_DATABASE\`.cargo
  UNION ALL SELECT 'usuario', COUNT(*) FROM \`$DB_DATABASE\`.usuario
  UNION ALL SELECT 'voo', COUNT(*) FROM \`$DB_DATABASE\`.voo;
"

echo ""
echo "=== Dados base OK ==="
echo "  Voos ANAC vêm do Apache POI: ./apache-po.sh"
echo ""
