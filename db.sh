#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Caminho completo para o arquivo .env
ENV_FILE="$SCRIPT_DIR/.env"

# Verificar se o arquivo .env existe
if [ -f "$ENV_FILE" ]; then
    # Carregar as variáveis de ambiente do arquivo .env
    source "$ENV_FILE"
else
    echo "Arquivo .env não encontrado em $ENV_FILE"
    exit 1
fi

# Comando para criar banco de dados
create_db() {
    local db_name=$1
    if db_exists "$db_name"; then
        echo -e "${GREEN}O banco de dados $db_name já existe${NC}"
        return
    fi

    local command="MYSQL_PWD=$DB_PASSWORD mysql -u$DB_USER -h$DB_HOST -P$DB_PORT -e 'CREATE DATABASE $db_name;'"
    eval $command
    echo -e "${GREEN}Banco de dados $db_name criado com sucesso${NC}"
}

# Comando para remover banco de dados
remove_db() {
    local db_name=$1
    if ! db_exists "$db_name"; then
        echo -e "${RED}O banco de dados $db_name não existe${NC}"
        return
    fi

    local command="MYSQL_PWD=$DB_PASSWORD mysql -u$DB_USER -h$DB_HOST -P$DB_PORT -e 'DROP DATABASE $db_name;'"
    eval $command
    echo -e "${RED}Banco de dados $db_name removido com sucesso${NC}"
}

# Verifica se o banco de dados existe
db_exists() {
    local db_name=$1
    local command="MYSQL_PWD=$DB_PASSWORD mysql -u$DB_USER -h$DB_HOST -P$DB_PORT -e 'SHOW DATABASES LIKE \"$db_name\";'"
    local output=$(eval $command)
    [ "$(echo "$output" | wc -l)" -gt 1 ]
}

# Ajuda do comando
help() {
    echo "Uso: db [comando] [nome_do_banco]"
    echo "Comandos:"
    echo "  create - cria um banco de dados"
    echo "  remove - remove um banco de dados"
    echo "  exists - verifica se um banco de dados existe"
}

# Executa o comando
if [ $# -lt 2 ]; then
    help
else
    command=$1
    db_name=$2
    case $command in
        create)
            create_db "$db_name"
            ;;
        remove)
            remove_db "$db_name"
            ;;
        exists)
            if db_exists "$db_name"; then
                echo -e "${GREEN}O banco de dados existe${NC}"
            else
                echo -e "${RED}O banco de dados não existe${NC}"
            fi
            ;;
        *)
            help
            ;;
    esac
fi
