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
APACHEPOI_IMAGE="${APACHEPOI_IMAGE:-lucasveneroso/ascent:ascent-apachepoi-s3}"

# Uma execução por vez (cron + manual não podem se atropelar).
LOCK_FILE="$SCRIPT_DIR/.start.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo ">> Outra execução do start.sh já está em andamento. Nada a fazer."
  exit 0
fi

# Nunca mexe na stack enquanto a importação ANAC estiver rodando.
if [ "$(docker inspect -f '{{.State.Running}}' ascent-apachepoi 2>/dev/null)" = "true" ]; then
  echo ">> Importação ANAC em andamento (ascent-apachepoi). Nenhuma alteração será feita."
  exit 0
fi

echo "=== 1. Atualizando repositório e imagens Docker (pull) ==="
git pull origin develop 2>/dev/null || git pull 2>/dev/null || true
docker pull mysql:8.0
docker pull lucasveneroso/ascent:ascent-api || true
docker pull lucasveneroso/ascent:ascent-logs || true
# A imagem do apachepoi é um job pontual. Só baixa se ainda não existir
# localmente, para um `docker pull` de tag antiga não sobrescrever o build fix.
if ! docker image inspect "$APACHEPOI_IMAGE" >/dev/null 2>&1; then
  docker pull "$APACHEPOI_IMAGE" || true
fi

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

echo "=== 3. Removendo apenas containers legados (fora do compose) ==="
# ascent-mysql e ascent-api são gerenciados pelo compose e têm
# restart: unless-stopped. NÃO são removidos aqui: fazer isso a cada
# execução derrubava a stack inteira (e a importação em andamento).
# Só remove um eventual container "mysql" antigo, criado por versões
# anteriores do start.sh, que não pertence a este projeto compose.
for antigo in mysql; do
  if docker inspect "$antigo" >/dev/null 2>&1; then
    dono="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$antigo" 2>/dev/null || true)"
    if [ -z "$dono" ]; then
      echo ">> Removendo container legado: $antigo"
      docker rm -f "$antigo" >/dev/null 2>&1 || true
    fi
  fi
done

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
# "up -d" já é idempotente: só recria o que mudou. Não usamos "down"
# porque ele derrubava MySQL/API (e a rede) a cada execução.
compose up -d --remove-orphans

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

echo "=== 5. Inicializando ascent-logs (cron garante que continue rodando) ==="
if [ -f "$SCRIPT_DIR/start-logs.sh" ]; then
  bash "$SCRIPT_DIR/start-logs.sh" || {
    echo ">> AVISO: Não foi possível iniciar ascent-logs (imagem não encontrada no Docker Hub)."
    echo "   O restante do sistema continua funcionando normalmente."
  }
else
  echo ">> AVISO: start-logs.sh não encontrado. ascent-logs não iniciado."
fi

echo "=== 6. Executando importação ANAC (ascent-apachepoi) uma única vez ==="
# O apachepoi é um job: roda até terminar e não volta sozinho.
# O runner (importar-anac.sh) cuida de lock, retomada e log persistente.
APACHEPOI_MARKER="$SCRIPT_DIR/.apachepoi-executado"

if [ -f "$APACHEPOI_MARKER" ]; then
  echo ">> Importação já concluída anteriormente ($APACHEPOI_MARKER). Pulando."
elif [ "$(docker inspect -f '{{.State.Running}}' ascent-apachepoi 2>/dev/null)" = "true" ]; then
  echo ">> Importação já está rodando. Pulando."
elif bash "$SCRIPT_DIR/importar-anac.sh"; then
  touch "$APACHEPOI_MARKER"
  echo ">> Importação concluída. Ela não será executada novamente."
else
  echo ">> AVISO: a importação falhou ou ficou incompleta. Será retomada na próxima execução."
fi

echo "=== 7. Configurando crontab (DuckDNS, start.sh e ascent-logs) ==="
if [ -f "$SCRIPT_DIR/setup-duckdns.sh" ]; then
  bash "$SCRIPT_DIR/setup-duckdns.sh"
else
  echo ">> AVISO: setup-duckdns.sh não encontrado. Crontab DuckDNS não configurado."
fi

# NÃO agendar start.sh/start-logs.sh de 5 em 5 minutos: isso derrubava a
# stack e matava a importação em andamento. Os containers têm
# restart: unless-stopped, então @reboot é suficiente.
chmod +x "$SCRIPT_DIR/start.sh" "$SCRIPT_DIR/start-logs.sh" "$SCRIPT_DIR/importar-anac.sh" 2>/dev/null || true
CRON_BOOT="@reboot /bin/bash $SCRIPT_DIR/start.sh >> $SCRIPT_DIR/start.log 2>&1"
CRON_LOGS_BOOT="@reboot /bin/bash $SCRIPT_DIR/start-logs.sh >/dev/null 2>&1"
(
  crontab -l 2>/dev/null \
    | grep -vF "$SCRIPT_DIR/start.sh" \
    | grep -vF "$SCRIPT_DIR/start-logs.sh"
  echo "$CRON_BOOT"
  echo "$CRON_LOGS_BOOT"
) | crontab -
echo ">> Crontab configurado: apenas @reboot (sem ciclos de 5 minutos)."

echo ""
echo "=== Sistema Ascent iniciado com sucesso! ==="
echo ""
echo "  API:         http://<IP>:3333"
echo "  Logs:        http://<IP>:8080 (mantido pelo cron)"
echo "  Apache POI:  importação única (não fica rodando)"
echo "  DuckDNS:     crontab a cada minuto (setup-duckdns.sh)"
echo ""
docker ps --filter "name=ascent" --filter "name=mysql" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
