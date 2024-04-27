#!/bin/bash

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Caminho para o arquivo .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Verificar se o arquivo .env existe
if [ -f "$ENV_FILE" ]; then
    # Carregar as variáveis de ambiente do arquivo .env
    source "$ENV_FILE"
else
    echo -e "${RED}Arquivo .env não encontrado em $ENV_FILE${NC}"
    exit 1
fi

# Caminho para o arquivo hosts do Windows
WINDOWS_HOSTS_FILE="/mnt/c/Windows/System32/drivers/etc/hosts"

# Verificar se o arquivo hosts do Windows existe
if [ ! -f "$WINDOWS_HOSTS_FILE" ]; then
    echo -e "${RED}Arquivo hosts do Windows não encontrado em $WINDOWS_HOSTS_FILE${NC}"
    exit 1
fi

# Adicionar um novo domínio ao arquivo hosts do Windows
add_host() {
    local domain=$1
    
    # Verificar se o domínio já existe no arquivo hosts
    if grep -q "$domain" "$WINDOWS_HOSTS_FILE"; then
        echo -e "${RED}O domínio $domain já está presente no arquivo hosts do Windows.${NC}"
        return
    fi

    # Adicionar o domínio ao arquivo hosts
    echo "127.0.0.1 $domain" | sudo tee -a "$WINDOWS_HOSTS_FILE" > /dev/null

    echo -e "${GREEN}Domínio $domain adicionado ao arquivo hosts do Windows com sucesso.${NC}"
}

# Remover um domínio do arquivo hosts do Windows
remove_host() {
    local domain=$1

    # Criar uma cópia temporária do arquivo hosts
    TEMP_FILE=$(mktemp)
    sudo cp "$WINDOWS_HOSTS_FILE" "$TEMP_FILE"

    # Remover o domínio do arquivo hosts
    sudo sed -i "/$domain/d" "$TEMP_FILE"
    
    # Substituir o arquivo hosts original com a cópia modificada
    sudo cp "$TEMP_FILE" "$WINDOWS_HOSTS_FILE"

    echo -e "${GREEN}Domínio $domain removido do arquivo hosts do Windows com sucesso.${NC}"
}

# Verificar se o número de argumentos está correto
if [ $# -lt 2 ]; then
    echo -e "${GREEN}Uso: hosts [comando] [domínio]${NC}"
    echo "Comandos:"
    echo "  add    - adiciona um novo domínio ao arquivo hosts do Windows"
    echo "  remove - remove um domínio do arquivo hosts do Windows"
    exit 1
fi

command=$1
domain=$2

case $command in
    add)
        add_host "$domain"
        ;;
    remove)
        remove_host "$domain"
        ;;
    *)
        echo -e "${RED}Comando inválido: $command${NC}"
        exit 1
        ;;
esac
