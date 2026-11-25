#!/bin/bash
# Compatibilidade: redireciona para importar-anac.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/importar-anac.sh" "$@"
