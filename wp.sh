#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Caminho completo para o arquivo .env
ENV_FILE="$SCRIPT_DIR/.env"

# Verificar se o arquivo .env existe
if [ -f "$ENV_FILE" ]; then
    # Carregar as variáveis de ambiente do arquivo .env
    source "$ENV_FILE"
    
    # Converter a string de plugins em array
    if [ -n "$WP_DEFAULT_PLUGINS" ]; then
        IFS=',' read -ra DEFAULT_PLUGINS <<< "$WP_DEFAULT_PLUGINS"
        # Remover espaços em branco dos elementos do array
        for i in "${!DEFAULT_PLUGINS[@]}"; do
            DEFAULT_PLUGINS[$i]=$(echo "${DEFAULT_PLUGINS[$i]}" | xargs)
        done
    else
        # Array vazio se não houver plugins definidos
        DEFAULT_PLUGINS=()
    fi
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

# Função para instalar plugins padrão
install_default_plugins() {
    local wp_path="$1"
    shift # Remove o primeiro argumento (wp_path)
    local additional_plugins=("$@") # Captura plugins adicionais
    
    # Instalar plugins padrão se configurados
    if [ ${#DEFAULT_PLUGINS[@]} -gt 0 ]; then
        echo -e "${GREEN}Instalando plugins padrão...${NC}"
        
        for plugin in "${DEFAULT_PLUGINS[@]}"; do
            if [ -n "$plugin" ]; then  # Verifica se o plugin não está vazio
                echo -e "${GREEN}Instalando plugin padrão: $plugin${NC}"
                wp plugin install "$plugin" --activate --path="$wp_path" --allow-root
                status=$?
                if [ $status -eq 0 ]; then
                    echo -e "${GREEN}Plugin $plugin instalado e ativado com sucesso${NC}"
                else
                    # Tenta instalar via ZIP local se não encontrar no repositório
                    local_zip="$SCRIPT_DIR/plugins/${plugin}.zip"
                    if [ -f "$local_zip" ]; then
                        echo -e "${YELLOW}Plugin $plugin não encontrado no repositório. Instalando via ZIP local: $local_zip${NC}"
                        wp plugin install "$local_zip" --activate --path="$wp_path" --allow-root
                        if [ $? -eq 0 ]; then
                            echo -e "${GREEN}Plugin $plugin instalado via ZIP com sucesso${NC}"
                        else
                            echo -e "${RED}Erro ao instalar o plugin $plugin via ZIP${NC}"
                        fi
                    else
                        echo -e "${RED}Erro ao instalar o plugin $plugin: não encontrado no repositório nem na pasta plugins${NC}"
                    fi
                fi
            fi
        done
    else
        echo -e "${GREEN}Nenhum plugin padrão configurado no .env${NC}"
    fi
    
    # Instalar plugins adicionais se fornecidos
    if [ ${#additional_plugins[@]} -gt 0 ]; then
        echo -e "${GREEN}Instalando plugins adicionais...${NC}"
        for plugin in "${additional_plugins[@]}"; do
            if [ -n "$plugin" ]; then  # Verifica se o plugin não está vazio
                echo -e "${GREEN}Instalando plugin adicional: $plugin${NC}"
                wp plugin install "$plugin" --activate --path="$wp_path" --allow-root
                status=$?
                if [ $status -eq 0 ]; then
                    echo -e "${GREEN}Plugin adicional $plugin instalado e ativado com sucesso${NC}"
                else
                    # Tenta instalar via ZIP local se não encontrar no repositório
                    local_zip="$SCRIPT_DIR/plugins/${plugin}.zip"
                    if [ -f "$local_zip" ]; then
                        echo -e "${YELLOW}Plugin adicional $plugin não encontrado no repositório. Instalando via ZIP local: $local_zip${NC}"
                        wp plugin install "$local_zip" --activate --path="$wp_path" --allow-root
                        if [ $? -eq 0 ]; then
                            echo -e "${GREEN}Plugin adicional $plugin instalado via ZIP com sucesso${NC}"
                        else
                            echo -e "${RED}Erro ao instalar o plugin adicional $plugin via ZIP${NC}"
                        fi
                    else
                        echo -e "${RED}Erro ao instalar o plugin adicional $plugin: não encontrado no repositório nem na pasta plugins${NC}"
                    fi
                fi
            fi
        done
    fi
}

# Verificar se o número de argumentos está correto
if [ $# -lt 2 ]; then
    echo "Uso: wp [comando] [domínio] [plugins_adicionais...]"
    echo "Comandos:"
    echo "  add    - adiciona um novo site WordPress"
    echo "  remove - remove um site WordPress existente"
    echo ""
    echo "Plugins padrão que serão instalados automaticamente (definidos no .env):"
    if [ ${#DEFAULT_PLUGINS[@]} -eq 0 ]; then
        echo "  Nenhum plugin padrão configurado"
    else
        for plugin in "${DEFAULT_PLUGINS[@]}"; do
            echo "  - $plugin"
        done
    fi
    echo ""
    echo "Exemplo com plugins adicionais:"
    echo "  wp add exemplo.com elementor woocommerce"
    echo ""
    echo "Para configurar plugins padrão, edite a variável WP_DEFAULT_PLUGINS no arquivo .env"
    exit 1
fi

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

command=$1
domain=$2
# Capturar plugins adicionais e .wpress (se houver)
shift 2 # Remove comando e domínio dos argumentos
wpress_file=""
if [ $# -gt 0 ]; then
    last_arg="${!#}"
    if [[ "$last_arg" == *.wpress ]]; then
        wpress_file="$last_arg"
        # Remove o último argumento do array de plugins
        unset "@"
        set -- "${@:1:$(($#-1))}"
    fi
fi
additional_plugins=("$@") # Todos os argumentos restantes são plugins adicionais

case $command in
    add)
        # Adicionar o domínio ao NGINX e configurar o PHP
        "$NGINX_SCRIPT" add "$domain"

        # Criar um banco de dados com prefixo "wp" e um usuário "user" com senha aleatória
        db_name="wp_${domain//[-.]/_}"  

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



        # Instalar plugins padrão somente se o wp-config.php existir
        if [ -f "$NGINX_ROOT_DIR/$domain/wp-config.php" ]; then
            install_default_plugins "$NGINX_ROOT_DIR/$domain" "${additional_plugins[@]}"
        else
            echo -e "${RED}wp-config.php não encontrado. Plugins não serão instalados.${NC}"
        fi

        # Importar .wpress se informado
        if [ -n "$wpress_file" ]; then
            "$SCRIPT_DIR/import-wpress.sh" "$NGINX_ROOT_DIR/$domain" "$wpress_file"
        fi

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
        echo -e "${GREEN}WordPress instalado com sucesso em http://$domain/wp-admin${NC}"
        ;;
    remove)
        # Remover o domínio do NGINX
        "$NGINX_SCRIPT" remove "$domain"

        # Remover o banco de dados associado ao domínio
        db_name="wp_${domain//[-.]/_}"
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
