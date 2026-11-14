#!/bin/bash
set -e

# Garante que o script funcione mesmo quando chamado de outro diretório
# (ex.: pelo cron com /home/usuario/site-Ascent/start.sh).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE="$SCRIPT_DIR/.env"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
PROJECT_NAME="ascent"
export COMPOSE_PROJECT_NAME="$PROJECT_NAME"

echo "=== 1. Atualizando repositório e imagens Docker (pull) ==="
git pull origin develop 2>/dev/null || git pull 2>/dev/null || true
docker pull mysql:8.0
docker pull lucasveneroso/ascent:ascent-api || true
docker pull lucasveneroso/ascent:ascent-logs || true
docker pull lucasveneroso/ascent:ascent-apachepoi || true

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
# Endereço do serviço Java de notificações dentro da rede Docker
NOTIFICADOR_URL=http://ascent-logs:8080

# =============================================================
# ascent-logs (Java — Notificações Slack/Email)
# =============================================================
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/EXEMPLO/GERAL
SLACK_WEBHOOK_CADASTRO_URL=https://hooks.slack.com/services/EXEMPLO/CADASTRO
EMAIL_REMETENTE=exemplo@gmail.com
SENHA_APP=exemplo_senha

# =============================================================
# ascent-apachepoi (Java — Leitura S3 ANAC)
# =============================================================
AWS_REGION=us-east-1
AWS_BUCKET=ascent-base-de-dados
AWS_PREFIXO_ARQUIVOS=anac_part_
AWS_TOTAL_PARTES=23
AWS_ARQUIVO_ANAC=anac_part_001.xlsx
AUTO_IMPORT=true

# Credenciais AWS — preencha com os valores do Vocareum/AWS Academy
# (Na EC2 com LabRole as chaves podem ficar vazias; a role cuida da autenticação)
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_SESSION_TOKEN=
EOF
echo ".env criado com sucesso!"
else
  echo ".env já existe. Usando configurações existentes."
fi

# Detecta se está rodando dentro de uma instância EC2 da AWS
IS_EC2=false
if curl -s -m 2 http://169.254.169.254/latest/meta-data/ 2>/dev/null | grep -q 'ami-id'; then
    IS_EC2=true
    echo ">> Ambiente AWS EC2 detectado! O ascent-apachepoi usará a IAM Role (LabRole) da máquina."
fi

echo "=== 3. Removendo containers antigos ==="
# Remove todos os containers do projeto (incluindo ascent-mysql legado do start.sh anterior)
docker rm -f ascent-mysql mysql ascent-api ascent-logs ascent-apachepoi 2>/dev/null || true

echo "=== 4. Subindo MySQL e ascent-api via docker compose ==="
# Detecta se é "docker compose" (v2) ou "docker-compose" (v1), instala se necessário
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

# Sempre usa o compose do diretório do projeto e um nome de projeto fixo.
# Isso evita o erro "no configuration file provided" quando o script roda
# a partir de outro diretório e garante que a rede se chame ascent_ascent.
compose() {
  "${COMPOSE[@]}" --project-name "$PROJECT_NAME" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

echo ">> Usando: ${COMPOSE[*]}"
compose down --remove-orphans 2>/dev/null || true
compose up -d --pull always

echo "=== 4.1. Aguardando o MySQL ficar pronto ==="
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

# Descobre dinamicamente a rede criada pelo compose (não depende do nome da pasta)
NETWORK="$(docker inspect -f '{{range $nome, $_ := .NetworkSettings.Networks}}{{$nome}}{{end}}' "$MYSQL_ID" 2>/dev/null || true)"
if [ -z "$NETWORK" ]; then
  NETWORK="${PROJECT_NAME}_ascent"
fi
echo ">> Rede Docker usada pelos serviços Java: $NETWORK"

echo "=== 5. Inicializando ascent-logs ==="
docker run -d \
  --name ascent-logs \
  --network "$NETWORK" \
  --restart unless-stopped \
  -p 8080:8080 \
  --env-file "$ENV_FILE" \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  lucasveneroso/ascent:ascent-logs || {
    echo ">> AVISO: Não foi possível iniciar ascent-logs (imagem não encontrada no Docker Hub)."
    echo "   O restante do sistema continua funcionando normalmente."
  }

echo "=== 6. Inicializando ascent-apachepoi ==="
# Na EC2 com LabRole: passa as credenciais da instância automaticamente via IAM Role.
# Localmente: usa as chaves definidas no .env.
if [ "$IS_EC2" = true ]; then
  ROLE_NAME=$(curl -s -m 2 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null)
  if [ -n "$ROLE_NAME" ]; then
    CREDS=$(curl -s -m 2 "http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME")
    EC2_KEY_ID=$(echo "$CREDS" | grep -o '"AccessKeyId" : "[^"]*"' | cut -d'"' -f4)
    EC2_SECRET=$(echo "$CREDS" | grep -o '"SecretAccessKey" : "[^"]*"' | cut -d'"' -f4)
    EC2_TOKEN=$(echo "$CREDS" | grep -o '"Token" : "[^"]*"' | cut -d'"' -f4)
    echo ">> Credenciais da LabRole obtidas via metadata da EC2."
    docker run -d \
      --name ascent-apachepoi \
      --network "$NETWORK" \
      --restart unless-stopped \
      -p 8081:8080 \
      --env-file "$ENV_FILE" \
      -e DB_HOST=mysql \
      -e DB_PORT=3306 \
      -e AWS_ACCESS_KEY_ID="$EC2_KEY_ID" \
      -e AWS_SECRET_ACCESS_KEY="$EC2_SECRET" \
      -e AWS_SESSION_TOKEN="$EC2_TOKEN" \
      lucasveneroso/ascent:ascent-apachepoi || {
        echo ">> AVISO: Não foi possível iniciar ascent-apachepoi (imagem não encontrada no Docker Hub)."
        echo "   O restante do sistema continua funcionando normalmente."
      }
  else
    echo ">> Aviso: não foi possível obter credenciais da LabRole. Usando .env."
    docker run -d \
      --name ascent-apachepoi \
      --network "$NETWORK" \
      --restart unless-stopped \
      -p 8081:8080 \
      --env-file "$ENV_FILE" \
      -e DB_HOST=mysql \
      -e DB_PORT=3306 \
      lucasveneroso/ascent:ascent-apachepoi || {
        echo ">> AVISO: Não foi possível iniciar ascent-apachepoi (imagem não encontrada no Docker Hub)."
        echo "   O restante do sistema continua funcionando normalmente."
      }
  fi
else
  docker run -d \
    --name ascent-apachepoi \
    --network "$NETWORK" \
    --restart unless-stopped \
    -p 8081:8080 \
    --env-file "$ENV_FILE" \
    -e DB_HOST=mysql \
    -e DB_PORT=3306 \
    lucasveneroso/ascent:ascent-apachepoi || {
      echo ">> AVISO: Não foi possível iniciar ascent-apachepoi (imagem não encontrada no Docker Hub)."
      echo "   O restante do sistema continua funcionando normalmente."
    }
fi

echo "=== 7. Configurando crontab (DuckDNS a cada minuto) ==="
if [ -f "$SCRIPT_DIR/setup-duckdns.sh" ]; then
  bash "$SCRIPT_DIR/setup-duckdns.sh"
else
  echo ">> AVISO: setup-duckdns.sh não encontrado. Crontab DuckDNS não configurado."
fi

echo ""
echo "=== Sistema Ascent iniciado com sucesso! ==="
echo ""
echo "  API:         http://<IP>:3333"
echo "  Logs:        http://<IP>:8080"
echo "  Apache POI:  http://<IP>:8081"
echo "  DuckDNS:     crontab a cada minuto (setup-duckdns.sh)"
echo ""
docker ps --filter "name=ascent" --filter "name=mysql" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
