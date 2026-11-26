#!/bin/bash
set -e

# =============================================================
# start.sh — Inicializa o sistema Ascent:
#   1. Prepara ambiente e volume persistente (/dados/mysql)
#   2. Derruba containers anteriores sem apagar volumes/dados
#   3. Atualiza imagens Docker via pull
#   4. Sobe a stack (MySQL + API) via docker compose no mesmo volume
#   5. Aplica schema e dados base se necessário (idempotente)
#   6. Sobe o container de logs (ascent-logs)
#   7. Configura DuckDNS e crontab @reboot
#   1. Prepara ambiente e volume de dados (/dados/mysql)
#   2. Derruba containers anteriores sem apagar volumes/dados
#   3. Atualiza imagens Docker via pull
#   4. Sobe a stack (MySQL + API) via docker compose
#   5. Aplica schema e dados base se necessário (idempotente)
#   6. Sobe o container de logs (ascent-logs)
#   7. Configura DuckDNS e crontab
#
# Importação ANAC (Apache POI): ./apache-po.sh
# start.sh — Atualiza imagens Docker, sobe MySQL + API + logs
#            e configura o DuckDNS.
#
# Importação ANAC (Apache POI): ./apache-po.sh
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

echo "=== 1. Detectando docker compose ==="
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

echo "=== 2. Atualizando repositório ==="
echo "=== 1. Atualizando repositório e imagens Docker ==="
git pull origin develop 2>/dev/null || git pull 2>/dev/null || true

echo "=== 3. Configurando ambiente (.env) ==="
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
# ascent-apachepoi (Java — Leitura S3 ANAC) — usado por importar-anac.sh
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

# Garante DB_HOST=mysql no .env
# Garante DB_HOST=mysql no .env (evita ascent-mysql / localhost quebrando containers).
if grep -q '^DB_HOST=' "$ENV_FILE"; then
  sed -i 's/^DB_HOST=.*/DB_HOST=mysql/' "$ENV_FILE"
else
  echo "DB_HOST=mysql" >> "$ENV_FILE"
fi

echo "=== 4. Preparando volume persistente do MySQL (/dados/mysql) ==="
# Sempre conecta o compose ao mesmo diretório /dados/mysql para preservar os dados.
sudo mkdir -p /dados/mysql 2>/dev/null || mkdir -p /dados/mysql 2>/dev/null || true
sudo chmod 777 /dados/mysql 2>/dev/null || chmod 777 /dados/mysql 2>/dev/null || true
echo ">> Diretório /dados/mysql verificado (dados preservados)."

echo "=== 5. Derrubando containers anteriores sem apagar volumes/dados ==="
RUNNING_CONTAINERS="$(compose ps --services --filter "status=running" 2>/dev/null || compose ps -q 2>/dev/null || true)"
if [ -n "$RUNNING_CONTAINERS" ] || docker ps --filter "name=ascent" --filter "name=mysql" -q 2>/dev/null | grep -q .; then
  echo ">> Compose/containers detectados de pé. Derrubando serviços sem apagar volumes..."
  compose down 2>/dev/null || true
else
  compose down 2>/dev/null || true
fi

echo "=== 3. Preparando volume do MySQL (Persistência no EBS em /dados/mysql) ==="
echo "=== 3. Removendo apenas containers legados (fora do compose) ==="
for antigo in mysql; do
  if docker inspect "$antigo" >/dev/null 2>&1; then
    dono="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$antigo" 2>/dev/null || true)"
    if [ -z "$dono" ]; then
      echo ">> Removendo container legado: $antigo"
      docker rm -f "$antigo" >/dev/null 2>&1 || true
    fi
  fi
done

echo "=== 4. Preparando volume do MySQL ==="
# Sem este diretório o compose pode falhar ou subir MySQL sem persistência.
sudo mkdir -p /dados/mysql 2>/dev/null || mkdir -p /dados/mysql 2>/dev/null || true
# Garante que o diretório do banco no EBS secundário existe
if [ "$IS_EC2" = true ]; then
  sudo mkdir -p /dados/mysql
  sudo chmod 777 /dados/mysql 2>/dev/null || true
else
  sudo mkdir -p /dados/mysql 2>/dev/null || mkdir -p /dados/mysql 2>/dev/null || true
  sudo chmod 777 /dados/mysql 2>/dev/null || chmod 777 /dados/mysql 2>/dev/null || true
fi

# Remove apenas containers remanescentes para evitar conflito de nome no Docker daemon
# (Nunca usa -v; dados em /dados/mysql continuam 100% preservados)
echo "=== 4. Validando se o compose está de pé ==="
COMPOSE_ATIVO=false

# Valida se há containers do compose rodando ou com status ativo
RUNNING_CONTAINERS="$(compose ps --services --filter "status=running" 2>/dev/null || compose ps -q 2>/dev/null || true)"
if [ -n "$RUNNING_CONTAINERS" ]; then
  COMPOSE_ATIVO=true
elif docker ps --filter "name=ascent" --filter "name=mysql" -q 2>/dev/null | grep -q .; then
  COMPOSE_ATIVO=true
fi

if [ "$COMPOSE_ATIVO" = true ]; then
  echo ">> Compose/containers detectados de pé. Derrubando serviços sem apagar dados/volumes..."
  compose down 2>/dev/null || true
  echo ">> Compose derrubado com sucesso. Dados preservados em /dados/mysql."
else
  echo ">> O compose não está de pé no momento. Prosseguindo..."
  compose down 2>/dev/null || true
fi

# Remove com segurança containers remanescentes para evitar conflito de nome no Docker daemon
# (Dados em /dados/mysql continuam 100% preservados no host/EBS)
for c in ascent-mysql ascent-api ascent-logs mysql; do
  if docker inspect "$c" >/dev/null 2>&1; then
    echo ">> Removendo container remanescente '$c' (volumes preservados)..."
    docker rm -f "$c" >/dev/null 2>&1 || true
  fi
done

echo "=== 6. Atualizando imagens Docker (pull) ==="
compose pull || true
docker pull lucasveneroso/ascent:ascent-logs || true
docker pull "${APACHEPOI_IMAGE:-lucasveneroso/ascent:ascent-apachepoi-s3}" || true
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

echo "=== 5. Atualizando imagens Docker (pull) ==="
echo ">> Baixando imagens atualizadas..."
compose pull || true
docker pull lucasveneroso/ascent:ascent-logs || true
docker pull "${APACHEPOI_IMAGE:-lucasveneroso/ascent:ascent-apachepoi-s3}" || true

echo "=== 6. Subindo containers atualizados via docker compose ==="
compose up -d --remove-orphans

echo "=== 7. Aguardando o MySQL ficar pronto ==="
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

echo "=== 8. Garantindo schema + dados iniciais no MySQL ==="
if [ -f "$SCRIPT_DIR/database/ascent.sql" ]; then
  DB_USER=$(grep -E "^DB_USER=" "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r')
  DB_PASSWORD=$(grep -E "^DB_PASSWORD=" "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r')
  DB_USER="${DB_USER:-admin}"
  DB_PASSWORD="${DB_PASSWORD:-admin}"

  docker exec -i ascent-mysql mysql -u"$DB_USER" -p"$DB_PASSWORD" < "$SCRIPT_DIR/database/ascent.sql" >/dev/null 2>&1 && \
    echo ">> Schema e dados conferidos com sucesso." || echo ">> AVISO: Não foi possível executar ascent.sql automaticamente."
fi

echo "=== 9. Inicializando ascent-logs ==="
NETWORK=""
if [ -n "$MYSQL_ID" ]; then
  NETWORK="$(docker inspect -f '{{range $nome, $_ := .NetworkSettings.Networks}}{{$nome}}{{end}}' "$MYSQL_ID" 2>/dev/null || true)"
fi
NETWORK="${NETWORK:-ascent_ascent}"

docker rm -f ascent-logs >/dev/null 2>&1 || true
docker run -d \
  --name ascent-logs \
  --network "$NETWORK" \
  --restart unless-stopped \
  -p 8080:8080 \
  --env-file "$ENV_FILE" \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  lucasveneroso/ascent:ascent-logs >/dev/null 2>&1 || {
    echo ">> AVISO: Não foi possível iniciar container ascent-logs."
  }

compose() {
  "${COMPOSE[@]}" --project-name "$PROJECT_NAME" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

echo "=== 7. Subindo MySQL e ascent-api via docker compose ==="
compose up -d --remove-orphans

echo "=== 8. Aguardando o MySQL ficar pronto ==="
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

echo "=== 9. Garantindo schema + dados iniciais no MySQL ==="
if [ -f "$SCRIPT_DIR/database/ascent.sql" ]; then
  DB_USER=$(grep -E "^DB_USER=" "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r')
  DB_PASSWORD=$(grep -E "^DB_PASSWORD=" "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r')
  DB_USER="${DB_USER:-admin}"
  DB_PASSWORD="${DB_PASSWORD:-admin}"

  docker exec -i ascent-mysql mysql -u"$DB_USER" -p"$DB_PASSWORD" < "$SCRIPT_DIR/database/ascent.sql" >/dev/null 2>&1 && \
    echo ">> Schema e dados conferidos com sucesso." || echo ">> AVISO: Não foi possível executar ascent.sql automaticamente."
fi

echo "=== 10. Inicializando ascent-logs ==="
NETWORK=""
if [ -n "$MYSQL_ID" ]; then
  NETWORK="$(docker inspect -f '{{range $nome, $_ := .NetworkSettings.Networks}}{{$nome}}{{end}}' "$MYSQL_ID" 2>/dev/null || true)"
fi
echo "=== 10. Configurando DuckDNS + crontab @reboot ==="
echo "=== 7. Inicializando ascent-logs ==="
if [ -f "$SCRIPT_DIR/start-logs.sh" ]; then
  bash "$SCRIPT_DIR/start-logs.sh" || {
    echo ">> AVISO: Não foi possível iniciar ascent-logs."
  }
else
  echo ">> AVISO: start-logs.sh não encontrado."
fi
NETWORK="${NETWORK:-ascent_ascent}"

docker rm -f ascent-logs >/dev/null 2>&1 || true
docker run -d \
  --name ascent-logs \
  --network "$NETWORK" \
  --restart unless-stopped \
  -p 8080:8080 \
  --env-file "$ENV_FILE" \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  lucasveneroso/ascent:ascent-logs >/dev/null 2>&1 || {
    echo ">> AVISO: Não foi possível iniciar container ascent-logs."
  }

echo "=== 11. Configurando DuckDNS + crontab @reboot ==="
if [ -f "$SCRIPT_DIR/setup-duckdns.sh" ]; then
  bash "$SCRIPT_DIR/setup-duckdns.sh"
else
  echo ">> AVISO: setup-duckdns.sh não encontrado."
fi

chmod +x "$SCRIPT_DIR/start.sh" "$SCRIPT_DIR/apache-po.sh" "$SCRIPT_DIR/setup-duckdns.sh" 2>/dev/null || true

CRON_BOOT="@reboot /bin/bash $SCRIPT_DIR/start.sh >> $SCRIPT_DIR/start.log 2>&1"
chmod +x "$SCRIPT_DIR/start.sh" "$SCRIPT_DIR/start-logs.sh" \
  "$SCRIPT_DIR/inserir-dados.sh" "$SCRIPT_DIR/importar-anac.sh" 2>/dev/null || true

CRON_BOOT="@reboot /bin/bash $SCRIPT_DIR/start.sh >> $SCRIPT_DIR/start.log 2>&1"
(
  crontab -l 2>/dev/null | grep -vF "$SCRIPT_DIR/start.sh"
  echo "$CRON_BOOT"
) | crontab -
echo ">> Crontab @reboot configurado."

echo ""
echo "=== Sistema Ascent iniciado ==="
echo ""
echo "  API:          http://<IP>:3333"
echo "  Logs:         http://<IP>:8080"
echo "  DuckDNS:      crontab a cada minuto"
echo "  Import ANAC:  ./apache-po.sh"
echo "  Seed MySQL:   ./inserir-dados.sh"
echo "  Import ANAC:  ./importar-anac.sh"
echo ""
docker ps --filter "name=ascent" --filter "name=mysql" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
