#!/bin/bash
# =============================================================
# setup-duckdns.sh — Configura DuckDNS na EC2
# Domínio: ascent-aviacao.duckdns.org
# =============================================================
set -e

TOKEN="d4e34aaf-78c5-46dc-8ca5-5ac210a36b42"
DOMAIN="ascent-aviacao"
EC2_IP="184.194.102.27"
DUCK_DIR="$HOME/duckdns"

echo "=== 1. Criando diretorio e script do DuckDNS ==="
mkdir -p "$DUCK_DIR"

cat << EOF > "$DUCK_DIR/duck.sh"
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip=${EC2_IP}" | curl -k -o ${DUCK_DIR}/duck.log -K -
EOF

chmod 700 "$DUCK_DIR/duck.sh"

echo "=== 2. Testando atualizacao do DuckDNS ==="
"$DUCK_DIR/duck.sh"
sleep 1

if grep -q "OK" "$DUCK_DIR/duck.log" 2>/dev/null; then
    echo ">> DuckDNS OK! IP atualizado com sucesso."
else
    echo ">> ATENCAO: resposta do DuckDNS:"
    cat "$DUCK_DIR/duck.log"
    echo ">> Verifique token e dominio."
fi

echo "=== 3. Agendando no cron (a cada minuto) ==="
CRON_JOB="* * * * * $DUCK_DIR/duck.sh >/dev/null 2>&1"

# Adiciona apenas se ainda nao existe
( crontab -l 2>/dev/null | grep -v "$DUCK_DIR/duck.sh" ; echo "$CRON_JOB" ) | crontab -

echo ">> Cron configurado."

echo "=== 4. Verificando dominio ==="
echo ">> DNS: $(dig +short $DOMAIN.duckdns.org 2>/dev/null || echo 'aguardando propagacao...')"

echo ""
echo "=== DuckDNS configurado com sucesso! ==="
echo "  Dominio: http://${DOMAIN}.duckdns.org"
echo "  Script:  $DUCK_DIR/duck.sh"
echo "  Log:     $DUCK_DIR/duck.log"
echo "  Cron:    a cada minuto"
