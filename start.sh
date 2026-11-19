#!/bin/bash
set -e

# =============================================================
# start.sh — Atualiza imagens Docker, sobe MySQL + API + logs
#            e configura o DuckDNS.
#
# NÃO roda Apache POI nem importa ANAC.
#   Schema/seed : ./inserir-dados.sh
#   Importação  : ./apache-po.sh
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE="$SCRIPT_DIR/.env"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
PROJECT_NAME="ascent"
export COMPOSE_PROJECT_NAME="$PROJECT_NAME"

LOCK_FILE="$SCRIPT_DIR/.start.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo ">> Outra execução do start.sh já está em andamento. Nada a fazer."
  exit 0
fi

echo "=== 1. Atualizando repositório e imagens Docker ==="
git pull origin develop 2>/dev/null || git pull 2>/dev/null || true
docker pull mysql:8.0
docker pull lucasveneroso/ascent:ascent-api || true
docker pull lucasveneroso/ascent:ascent-logs || true

echo "=== 2. Configurando ambiente (.env) ==="
if [ ! -f "$ENV_FILE" ]; then
cat << 'EOF' > "$ENV_FILE"
# =============================================================
# Banco de Dados MySQL (Container mysql)
# Dentro da rede Docker o host correto é "mysql".
# =============================================================
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=ascent
DB_USER=admin
DB_PASSWORD=admin
DB_ROOT_PASSWORD=root
MYSQL_ROOT_PASSWORD=root

# =============================================================
# ascent-api (Node.js)
# =============================================================
APP_HOST=0.0.0.0
APP_PORT=3333
AMBIENTE_PROCESSO=producao
NOTIFICADOR_URL=http://ascent-logs:8080

# =============================================================
# ascent-logs (Java — Notificações Slack/Email)
# =============================================================
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/EXEMPLO/GERAL
SLACK_WEBHOOK_CADASTRO_URL=https://hooks.slack.com/services/EXEMPLO/CADASTRO
EMAIL_REMETENTE=exemplo@gmail.com
SENHA_APP=exemplo_senha

# =============================================================
# ascent-apachepoi (Java — Leitura S3 ANAC) — usado por apache-po.sh
# =============================================================
AWS_REGION=us-east-1
AWS_BUCKET=ascent-base-de-dados
AWS_PREFIXO_ARQUIVOS=anac_part_
AWS_TOTAL_PARTES=23
AWS_ARQUIVO_ANAC=anac_part_001.xlsx
AUTO_IMPORT=true

# Na EC2 com LabRole deixe as chaves vazias.
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_SESSION_TOKEN=
EOF
echo ".env criado com sucesso!"
else
  echo ".env já existe. Usando configurações existentes."
fi

# Garante DB_HOST=mysql no .env (evita ascent-mysql / localhost quebrando containers).
if grep -q '^DB_HOST=' "$ENV_FILE"; then
  sed -i 's/^DB_HOST=.*/DB_HOST=mysql/' "$ENV_FILE"
else
  echo "DB_HOST=mysql" >> "$ENV_FILE"
fi

echo "=== 3. Verificando status dos serviços e preservando dados ==="
for servico in ascent-mysql ascent-api ascent-logs; do
  if docker inspect "$servico" >/dev/null 2>&1; then
    st="$(docker inspect -f '{{if .State.Running}}rodando (uptime: {{.State.StartedAt}}){{else}}parado{{end}}' "$servico" 2>/dev/null || echo desconhecido)"
    echo ">> Serviço '$servico' detectado: $st. Dados e volumes preservados."
  fi
done

# Remove apenas container legado solto chamado 'mysql' (se não fizer parte do compose) para evitar conflito de porta
if docker inspect mysql >/dev/null 2>&1; then
  dono="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' mysql 2>/dev/null || true)"
  if [ -z "$dono" ]; then
    echo ">> Removendo container legado órfão 'mysql' sem projeto compose (dados em volumes não são afetados)."
    docker rm -f mysql >/dev/null 2>&1 || true
  fi
fi

echo "=== 4. Preparando volume do MySQL (Persistência no EBS em /dados/mysql) ==="
# Garante a existência do diretório no EBS sem apagar arquivos existentes
if [ "$IS_EC2" = true ]; then
  sudo mkdir -p /dados/mysql
  sudo chmod 777 /dados/mysql 2>/dev/null || true
else
  sudo mkdir -p /dados/mysql 2>/dev/null || mkdir -p /dados/mysql 2>/dev/null || true
  sudo chmod 777 /dados/mysql 2>/dev/null || chmod 777 /dados/mysql 2>/dev/null || true
fi
echo ">> Diretório /dados/mysql verificado."

echo "=== 5. Subindo MySQL e ascent-api via docker compose ==="
if docker compose version &>/dev/null; then
  COMPOSE=(docker compose)
elif command -v docker-compose &>/dev/null; then
  COMPOSE=(docker-compose)
else
  echo ">> docker compose não encontrado. Instalando plugin..."
  DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  mkdir -p "$DOCKER_CONFIG/cli-plugins"
  curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
    -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
  chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
  if docker compose version &>/dev/null; then
    COMPOSE=(docker compose)
    echo ">> Plugin instalado com sucesso!"
  else
    echo "ERRO: Não foi possível instalar docker compose. Abortando."
    exit 1
  fi
fi

compose() {
  "${COMPOSE[@]}" --project-name "$PROJECT_NAME" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

echo ">> Usando: ${COMPOSE[*]}"
compose up -d --remove-orphans

echo "=== 5.1. Aguardando o MySQL ficar pronto ==="
MYSQL_ID="$(compose ps -q mysql 2>/dev/null | head -n1)"
if [ -n "$MYSQL_ID" ]; then
  for _ in $(seq 1 60); do
    STATUS="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$MYSQL_ID" 2>/dev/null || echo desconhecido)"
    if [ "$STATUS" = "healthy" ] || [ "$STATUS" = "running" ]; then
      echo ">> MySQL pronto (status: $STATUS)."
      break
    fi
    sleep 2
  done
fi

echo "=== 6. Garantindo schema + dados iniciais no MySQL ==="
# Volume /dados/mysql já existente → initdb.d NÃO roda. Por isso o seed é explícito.
if [ -f "$SCRIPT_DIR/inserir-dados.sh" ]; then
  bash "$SCRIPT_DIR/inserir-dados.sh" || {
    echo ">> AVISO: inserir-dados.sh falhou. Rode manualmente depois."
  }
else
  echo ">> AVISO: inserir-dados.sh não encontrado."
fi

echo "=== 7. Inicializando ascent-logs ==="
if [ -f "$SCRIPT_DIR/start-logs.sh" ]; then
  bash "$SCRIPT_DIR/start-logs.sh" || {
    echo ">> AVISO: Não foi possível iniciar ascent-logs."
  }
else
  echo ">> AVISO: start-logs.sh não encontrado."
fi

echo "=== 8. Configurando DuckDNS + crontab @reboot ==="
if [ -f "$SCRIPT_DIR/setup-duckdns.sh" ]; then
  bash "$SCRIPT_DIR/setup-duckdns.sh"
else
  echo ">> AVISO: setup-duckdns.sh não encontrado."
fi

chmod +x "$SCRIPT_DIR/start.sh" "$SCRIPT_DIR/start-logs.sh" \
  "$SCRIPT_DIR/inserir-dados.sh" "$SCRIPT_DIR/apache-po.sh" 2>/dev/null || true

CRON_BOOT="@reboot /bin/bash $SCRIPT_DIR/start.sh >> $SCRIPT_DIR/start.log 2>&1"
CRON_LOGS_BOOT="@reboot /bin/bash $SCRIPT_DIR/start-logs.sh >/dev/null 2>&1"
(
  crontab -l 2>/dev/null \
    | grep -vF "$SCRIPT_DIR/start.sh" \
    | grep -vF "$SCRIPT_DIR/start-logs.sh"
  echo "$CRON_BOOT"
  echo "$CRON_LOGS_BOOT"
) | crontab -
echo ">> Crontab: apenas @reboot (DuckDNS fica no setup-duckdns.sh)."

echo ""
echo "=== Sistema Ascent iniciado ==="
echo ""
echo "  API:          http://<IP>:3333"
echo "  Logs:         http://<IP>:8080"
echo "  DuckDNS:      crontab a cada minuto"
echo "  Seed MySQL:   ./inserir-dados.sh"
echo "  Import ANAC:  ./apache-po.sh"
echo ""
docker ps --filter "name=ascent" --filter "name=mysql" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
