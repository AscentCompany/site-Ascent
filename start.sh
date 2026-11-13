#!/bin/bash
set -e

echo "=== 1. Atualizando repositório e imagens Docker (pull) ==="
git pull origin develop 2>/dev/null || git pull 2>/dev/null || true
docker pull mysql:8.0
docker pull lucasveneroso/ascent:ascent-api || true
docker pull lucasveneroso/ascent:ascent-logs || true
docker pull lucasveneroso/ascent:ascent-apachepoi || true

echo "=== 2. Configurando ambiente (.env) ==="
if [ ! -f .env ]; then
cat << 'EOF' > .env
# =============================================================
# Banco de Dados MySQL (Container ascent-mysql)
# =============================================================
DB_HOST=ascent-mysql
DB_PORT=3306
DB_DATABASE=ascent
DB_USER=admin
DB_PASSWORD=admin
DB_ROOT_PASSWORD=root

# =============================================================
# ascent-api (Node.js)
# =============================================================
APP_HOST=0.0.0.0
APP_PORT=3333
AMBIENTE_PROCESSO=producao

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

echo "=== 3. Preparando rede, diretórios e limpando containers antigos ==="
if [ "$IS_EC2" = true ]; then
    sudo mkdir -p /dados/mysql
    MYSQL_VOLUME=/dados/mysql
else
    mkdir -p ./dados/mysql
    MYSQL_VOLUME=$(pwd)/dados/mysql
fi

docker network create ascent 2>/dev/null || true
docker rm -f ascent-mysql ascent-api ascent-logs ascent-apachepoi 2>/dev/null || true

echo "=== 4. Inicializando MySQL ==="
docker run -d \
  --name ascent-mysql \
  --network ascent \
  --restart unless-stopped \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=ascent \
  -e MYSQL_USER=admin \
  -e MYSQL_PASSWORD=admin \
  -v "$MYSQL_VOLUME":/var/lib/mysql \
  mysql:8.0

echo "Aguardando MySQL inicializar e aceitar conexões..."
for i in $(seq 1 60); do
  if docker exec ascent-mysql mysqladmin ping -u root -proot --silent 2>/dev/null; then
    echo "MySQL pronto em ${i}s!"
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "ERRO: MySQL não respondeu em 60 segundos. Abortando."
    exit 1
  fi
  sleep 1
done

echo "=== Aplicando schema do banco de dados ==="

if [ ! -f database/ascent.sql ]; then
    echo "ERRO: database/ascent.sql não encontrado. Verifique se o 'git pull' funcionou."
    exit 1
fi

# Importa apenas se o banco ainda não tem tabelas (idempotente — evita
# duplicar dados de seed em re-execuções)
TABLE_COUNT=$(docker exec ascent-mysql mysql -u root -proot ascent -N \
    -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='ascent'" 2>/dev/null || echo "0")

if [ "${TABLE_COUNT:-0}" -eq 0 ] 2>/dev/null; then
    echo "Importando schema (database/ascent.sql)..."
    docker exec -i ascent-mysql mysql -u root -proot ascent < database/ascent.sql
    echo "Schema aplicado com sucesso!"
else
    echo "Banco já possui ${TABLE_COUNT} tabelas. Pulando importação do schema."
fi

echo "=== 5. Inicializando ascent-api ==="
docker run -d \
  --name ascent-api \
  --network ascent \
  --restart unless-stopped \
  -p 3333:3333 \
  --env-file .env \
  lucasveneroso/ascent:ascent-api

echo "=== 6. Inicializando ascent-logs ==="
docker run -d \
  --name ascent-logs \
  --network ascent \
  --restart unless-stopped \
  -p 8080:8080 \
  --env-file .env \
  lucasveneroso/ascent:ascent-logs

echo "=== 7. Inicializando ascent-apachepoi ==="
# Na EC2 com LabRole: passa as credenciais da instância automaticamente via IAM Role.
# Localmente: usa as chaves definidas no .env.
if [ "$IS_EC2" = true ]; then
  # Obtém credenciais temporárias via metadata da EC2 (LabRole)
  ROLE_NAME=$(curl -s -m 2 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null)
  if [ -n "$ROLE_NAME" ]; then
    CREDS=$(curl -s -m 2 "http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME")
    EC2_KEY_ID=$(echo "$CREDS" | grep -o '"AccessKeyId" : "[^"]*"' | cut -d'"' -f4)
    EC2_SECRET=$(echo "$CREDS" | grep -o '"SecretAccessKey" : "[^"]*"' | cut -d'"' -f4)
    EC2_TOKEN=$(echo "$CREDS" | grep -o '"Token" : "[^"]*"' | cut -d'"' -f4)
    echo ">> Credenciais da LabRole obtidas via metadata da EC2."
    docker run -d \
      --name ascent-apachepoi \
      --network ascent \
      --restart unless-stopped \
      -p 8081:8080 \
      --env-file .env \
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
      --network ascent \
      --restart unless-stopped \
      -p 8081:8080 \
      --env-file .env \
      lucasveneroso/ascent:ascent-apachepoi || {
        echo ">> AVISO: Não foi possível iniciar ascent-apachepoi (imagem não encontrada no Docker Hub)."
        echo "   O restante do sistema continua funcionando normalmente."
      }
  fi
else
  docker run -d \
    --name ascent-apachepoi \
    --network ascent \
    --restart unless-stopped \
    -p 8081:8080 \
    --env-file .env \
    lucasveneroso/ascent:ascent-apachepoi || {
      echo ">> AVISO: Não foi possível iniciar ascent-apachepoi (imagem não encontrada no Docker Hub)."
      echo "   O restante do sistema continua funcionando normalmente."
    }
fi

echo "=== 8. Configurando crontab (DuckDNS a cada minuto) ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
docker ps --filter "name=ascent-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
