#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Caminho completo para o arquivo .env
ENV_FILE="$SCRIPT_DIR/.env"

# Verificar se o arquivo .env existe
if [ -f "$ENV_FILE" ]; then
    # Carregar as variáveis de ambiente do arquivo .env
    source "$ENV_FILE"
else
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}Arquivo .env não encontrado em $ENV_FILE${NC}"
    exit 1
fi

# Verificar se o script nginx.sh existe
NGINX_SCRIPT="$SCRIPT_DIR/nginx.sh"
if [ ! -f "$NGINX_SCRIPT" ]; then
    echo "Script nginx.sh não encontrado em $NGINX_SCRIPT"
    exit 1
fi

# Verificar se o script db.sh existe
DB_SCRIPT="$SCRIPT_DIR/db.sh"
if [ ! -f "$DB_SCRIPT" ]; then
    echo "Script db.sh não encontrado em $DB_SCRIPT"
    exit 1
fi

# Verificar se o WP CLI está instalado
if ! command -v wp &> /dev/null; then
    echo "WP CLI não encontrado. Por favor, instale o WP CLI antes de continuar."
    exit 1
fi

# Verificar se o número de argumentos está correto
if [ $# -lt 2 ]; then
    echo "Uso: wp [comando] [domínio]"
    echo "Comandos:"
    echo "  add    - adiciona um novo site WordPress"
    echo "  remove - remove um site WordPress existente"
    exit 1
fi

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

command=$1
domain=$2

case $command in
    add)
        # Adicionar o domínio ao NGINX e configurar o PHP
        "$NGINX_SCRIPT" add "$domain"

        # Criar um banco de dados com prefixo "wp" e um usuário "user" com senha aleatória
        db_name="wp_${domain//./_}"

        # Adicionar o domínio ao banco de dados
        "$DB_SCRIPT" create "$db_name"

        # Criar o diretório para o novo domínio
        mkdir -p "$NGINX_ROOT_DIR"

        # Baixar e instalar o WordPress usando o WP CLI
        wp core download --path="$NGINX_ROOT_DIR/$domain" --locale=pt_BR --allow-root

        # Configurar o WordPress
        wp config create --dbname="$db_name" --dbuser="$DB_USER" --dbpass="$DB_PASSWORD" --dbhost="$DB_HOST" --path="$NGINX_ROOT_DIR/$domain" --allow-root

        # Gerar um nome de usuário e senha aleatórios para o WordPress
        wp_user="user"
        wp_password=$(openssl rand -base64 12)

        # Instalar o WordPress
        wp core install --url="http://$domain" --title="My WordPress Site" --admin_user="${wp_user}" --admin_password="${wp_password}" --admin_email="admin@$domain" --path="$NGINX_ROOT_DIR/$domain" --allow-root

        # muda o proprietário do diretório do site para o usuário www-data
        chown -R www-data:www-data "$NGINX_ROOT_DIR/$domain"
        chmod -R 755 "$NGINX_ROOT_DIR/$domain"
        chmod -R 777 "$NGINX_ROOT_DIR/$domain/wp-content"


        # Exibir o nome de usuário e senha do WordPress
        echo -e "${GREEN}Usuário do WordPress:${NC} $wp_user"
        echo -e "${GREEN}Senha do WordPress:${NC} $wp_password"

        # Salvar o nome de usuário e senha do WordPress em um arquivo de texto na pasta do site
        echo "Usuário do WordPress: $wp_user" > "$NGINX_ROOT_DIR/$domain/wordpress_credentials.txt"
        echo "Senha do WordPress: $wp_password" >> "$NGINX_ROOT_DIR/$domain/wordpress_credentials.txt"

        # Mensagem de conclusão
        echo -e "${GREEN}WordPress instalado com sucesso em http://$domain${NC}"
        ;;
    remove)
        # Remover o domínio do NGINX
        "$NGINX_SCRIPT" remove "$domain"

        # Remover o banco de dados associado ao domínio
        db_name="wp_${domain//./_}"
        "$DB_SCRIPT" remove "$db_name"

        # Remover o diretório do domínio
        rm -rf "$NGINX_ROOT_DIR/$domain"

        # Mensagem de conclusão
        echo -e "${GREEN}WordPress removido com sucesso do domínio $domain${NC}"
        ;;
    *)
        echo -e "${RED}Comando inválido: $command${NC}"
        exit 1
        ;;
esac
