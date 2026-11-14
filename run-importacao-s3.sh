#!/bin/bash
set -e

IMAGEM="lucasveneroso/ascent:ascent-apachepoi-s3"
CONTAINER="ascent-apachepoi-s3"

echo "=== Ascent — Importação S3 (teste isolado) ==="

# Atualiza a imagem
echo ">> Baixando imagem mais recente..."
docker pull "$IMAGEM"

# Remove container anterior se existir
docker rm -f "$CONTAINER" 2>/dev/null || true

# Detecta qual rede e host do banco usar
if docker network ls --format '{{.Name}}' | grep -q '^ascent_ascent$'; then
    REDE="ascent_ascent"
    DB_HOST="mysql"
    echo ">> Rede encontrada: ascent_ascent | DB_HOST=mysql"
else
    # Compose não está rodando — tenta conectar via IP do host Docker
    REDE="ascent-s3-test"
    DB_HOST=$(docker network inspect bridge --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null || echo "172.17.0.1")
    docker network create "$REDE" 2>/dev/null || true
    echo ">> Rede ascent_ascent não encontrada. Usando rede: $REDE | DB_HOST=$DB_HOST"
    echo ">> ATENÇÃO: certifique-se que o MySQL está rodando e acessível."
fi

# Carrega .env
if [ ! -f .env ]; then
    echo "ERRO: arquivo .env não encontrado. Crie um a partir do .env.example"
    exit 1
fi

# Na EC2 com LabRole: injeta as credenciais temporárias automaticamente
IS_EC2=false
if curl -s -m 2 http://169.254.169.254/latest/meta-data/ 2>/dev/null | grep -q 'ami-id'; then
    IS_EC2=true
fi

echo ">> Iniciando importação..."
echo ""

if [ "$IS_EC2" = true ]; then
    ROLE_NAME=$(curl -s -m 2 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null)
    CREDS=$(curl -s -m 2 "http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME")
    EC2_KEY_ID=$(echo "$CREDS" | grep -o '"AccessKeyId" : "[^"]*"' | cut -d'"' -f4)
    EC2_SECRET=$(echo "$CREDS" | grep -o '"SecretAccessKey" : "[^"]*"' | cut -d'"' -f4)
    EC2_TOKEN=$(echo "$CREDS"  | grep -o '"Token" : "[^"]*"'          | cut -d'"' -f4)
    echo ">> Credenciais IAM Role obtidas via metadata da EC2."

    docker run --rm \
        --name "$CONTAINER" \
        --network "$REDE" \
        --env-file .env \
        -e DB_HOST="$DB_HOST" \
        -e AWS_ACCESS_KEY_ID="$EC2_KEY_ID" \
        -e AWS_SECRET_ACCESS_KEY="$EC2_SECRET" \
        -e AWS_SESSION_TOKEN="$EC2_TOKEN" \
        "$IMAGEM"
else
    docker run --rm \
        --name "$CONTAINER" \
        --network "$REDE" \
        --env-file .env \
        -e DB_HOST="$DB_HOST" \
        "$IMAGEM"
fi

echo ""
echo "=== Importação finalizada ==="
