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

# Comando para adicionar certificado SSL
add_ssl() {
    local domain=$1

    # Verificar se o Certbot está instalado
    if ! command -v certbot &>/dev/null; then
        echo -e "${RED}Certbot não encontrado. Por favor, instale-o primeiro.${NC}"
        exit 1
    fi

    # Executar o Certbot para obter o certificado SSL
    sudo certbot --nginx -d "$domain" --non-interactive --agree-tos -m "$SSL_EMAIL"

    # Verificar se o certificado SSL foi obtido com sucesso
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Certificado SSL configurado para o domínio $domain${NC}"
    else
        echo -e "${RED}Falha ao configurar o certificado SSL${NC}"
        exit 1
    fi
}

# Comando para remover certificado SSL
remove_ssl() {
    local domain=$1

    # Verificar se o Certbot está instalado
    if ! command -v certbot &>/dev/null; then
        echo -e "${RED}Certbot não encontrado. Por favor, instale-o primeiro.${NC}"
        exit 1
    fi

    # Remover o certificado SSL para o domínio especificado
    sudo certbot delete --cert-name "$domain"

    # Verificar se o certificado SSL foi removido com sucesso
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Certificado SSL removido para o domínio $domain${NC}"
    else
        echo -e "${RED}Falha ao remover o certificado SSL${NC}"
        exit 1
    fi
}

# Ajuda do comando
help() {
    echo "Uso: ssl [comando] [domínio]"
    echo "Comandos:"
    echo "  add    - adiciona um certificado SSL para o domínio especificado"
    echo "  remove - remove o certificado SSL para o domínio especificado"
}

# Executa o comando
if [ $# -lt 2 ]; then
    help
else
    command=$1
    domain=$2
    case $command in
        add)
            add_ssl "$domain"
            ;;
        remove)
            remove_ssl "$domain"
            ;;
        *)
            help
            ;;
    esac
fi
