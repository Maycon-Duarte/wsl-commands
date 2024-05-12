#!/bin/bash

# Arquivo de configuração
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Carregar variáveis de ambiente do arquivo .env
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}Arquivo .env não encontrado em $ENV_FILE${NC}"
    exit 1
fi

# Função para adicionar um registro DNS no Route 53
add_dns_record() {
    local domain=$1
    local ip_address=$AWS_DOMAIN_IP

    # Comando para adicionar registro DNS no Route 53
    aws route53 change-resource-record-sets --hosted-zone-id "$AWS_HOSTED_ZONE_ID" --change-batch '{
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'"$domain"'",
                    "Type": "A",
                    "TTL": 60,
                    "ResourceRecords": [
                        {
                            "Value": "'"$ip_address"'"
                        }
                    ]
                }
            }
        ]
    }'

    echo -e "${GREEN}Registro DNS para $domain adicionado com sucesso no Route 53.${NC}"

    # Esperar a propagação do DNS
    wait_for_dns_propagation "$domain"
}

# Função para esperar a propagação do DNS
wait_for_dns_propagation() {
    local domain=$1
    local timeout=60  # Tempo limite em segundos
    local start_time=$(date +%s)
    local end_time=$((start_time + timeout))

    echo "Esperando a propagação do DNS para $domain..."

    # Loop até que o domínio seja resolvido corretamente ou o tempo limite seja atingido
    while true; do
        # Tente resolver o domínio usando o comando "nslookup" ou similar
        if nslookup "$domain" >/dev/null 2>&1; then
            echo "O domínio $domain foi propagado com sucesso!"
            break
        fi

        # Verifique se o tempo limite foi atingido
        local current_time=$(date +%s)
        if [ $current_time -ge $end_time ]; then
            echo "O tempo limite de espera foi atingido. A propagação do DNS para $domain pode não ter sido concluída."
            break
        fi

        # Aguarde um curto período antes de tentar novamente
        sleep 10
    done
}

# Função para remover um registro DNS no Route 53
remove_dns_record() {
    local domain=$1
    local ip_address=$AWS_DOMAIN_IP

    # Comando para remover registro DNS no Route 53
    aws route53 change-resource-record-sets --hosted-zone-id "$AWS_HOSTED_ZONE_ID" --change-batch '{
        "Changes": [
            {
                "Action": "DELETE",
                "ResourceRecordSet": {
                    "Name": "'"$domain"'",
                    "Type": "A",
                    "TTL": 60,
                    "ResourceRecords": [
                        {
                            "Value": "'"$ip_address"'"
                        }
                    ]
                }
            }
        ]
    }'

    echo -e "${RED}Registro DNS para $domain removido com sucesso do Route 53.${NC}"
}

# Ajuda do script
help() {
    echo -e "${GREEN}Uso: router53 [comando] [domínio]${NC}"
    echo "Comandos:"
    echo "  add    - adiciona um registro DNS ao Route 53"
    echo "  remove - remove um registro DNS do Route 53"
}

# Executa o comando
if [ $# -lt 2 ]; then
    help
else
    command=$1
    domain=$2
    case $command in
        add)
            add_dns_record "$domain"
            ;;
        remove)
            remove_dns_record "$domain"
            ;;
        *)
            help
            ;;
    esac
fi
