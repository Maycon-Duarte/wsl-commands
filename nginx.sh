#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Caminho completo para o arquivo .env
ENV_FILE="$SCRIPT_DIR/.env"

# Verificar se o arquivo .env existe
if [ -f "$ENV_FILE" ]; then
    # Carregar as variáveis de ambiente do arquivo .env
    source "$ENV_FILE"
else
    echo -e "${RED}Arquivo .env não encontrado em $ENV_FILE${NC}"
    exit 1
fi

# Limpa o terminal
clear

# Adiciona um novo domínio ao NGINX e configura o PHP
add_domain() {
    local config_file="${NGINX_AVALIABLE_DIR}/${domain}"
    local domain_root="${NGINX_ROOT_DIR}/${domain}"

    
    # Verifica se o domínio já existe
    if [ -f "$config_file" ]; then
        echo -e "${RED}O domínio $domain já está configurado no NGINX.${NC}"
        return
    fi

    # Cria o diretório para o domínio
    mkdir -p "$domain_root"

    # Cria o arquivo de configuração para o novo domínio
    cat > "$config_file" <<EOF
server {
    listen 80;
    server_name $domain;
    root $domain_root;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

    # Cria um arquivo index.php de exemplo
    cat > "$domain_root/index.php" <<EOF
<?php
phpinfo();
?>
EOF

    # Cria um link simbólico para ativar o domínio
    ln -s "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain"

    # Recarrega o serviço do NGINX para aplicar as alterações
    systemctl reload nginx

    echo -e "${GREEN}Domínio $domain adicionado com sucesso ao NGINX.${NC}"

    if [ "$HOSTS_ACTIVE" == "true" ]; then
        # Chama o script hosts.sh para adicionar o domínio ao arquivo hosts do Windows
       "$SCRIPT_DIR/hosts.sh" add "$domain"    
    fi    

    if [ "$AWS_CLI_ACTIVE" == "true" ]; then
        # Chama o script hosts.sh para remover o domínio do arquivo hosts do Windows
        "$SCRIPT_DIR/route53.sh" add "$domain"        
    fi

    if [ "$SSL_ACTIVE" == "true" ]; then
        # Chama o script hosts.sh para adicionar o domínio ao arquivo hosts do Windows
       "$SCRIPT_DIR/ssl.sh" add "$domain"    
    fi    
}

# Remove um domínio do NGINX
remove_domain() {
    local domain=$1
    local config_file="${NGINX_AVALIABLE_DIR}/${domain}"
    local domain_root="${NGINX_ROOT_DIR}/${domain}"
    
    # Verifica se o domínio existe
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}O domínio $domain não está configurado no NGINX.${NC}"
        return
    fi

    # Remove o arquivo de configuração do domínio
    rm "$config_file"

    # Remove o link simbólico do domínio
    rm "/etc/nginx/sites-enabled/$domain"

    # Remove o diretório do domínio
    rm -rf "$domain_root"

    # Recarrega o serviço do NGINX para aplicar as alterações
    systemctl reload nginx

    echo -e "${RED}Domínio $domain removido com sucesso do NGINX.${NC}"

    if [ "$HOSTS_ACTIVE" == "true" ]; then
        # Chama o script hosts.sh para remover o domínio do arquivo hosts do Windows
        "$SCRIPT_DIR/hosts.sh" remove "$domain"        
    fi

    if [ "$AWS_CLI_ACTIVE" == "true" ]; then
        # Chama o script hosts.sh para remover o domínio do arquivo hosts do Windows
        "$SCRIPT_DIR/route53.sh" remove "$domain"        
    fi

    # if [ "$SSL_ACTIVE" == "true" ]; then
    #     # Chama o script hosts.sh para adicionar o domínio ao arquivo hosts do Windows
    #     #"$SCRIPT_DIR/ssl.sh" remove "$domain"    
    # fi       
}

# Ajuda do script
help() {
    echo -e "${GREEN}Uso: nginx [comando] [domínio]${NC}"
    echo "Comandos:"
    echo "  add    - adiciona um domínio ao NGINX e configura o PHP"
    echo "  remove - remove um domínio do NGINX"
}

# Executa o comando
if [ $# -lt 2 ]; then
    help
else
    command=$1
    domain=$2
    case $command in
        add)
            add_domain "$domain"
            ;;
        remove)
            remove_domain "$domain"
            ;;
        *)
            help
            ;;
    esac
fi
