#!/bin/bash
# Script para importar um arquivo .wpress usando WP CLI
# Uso: ./import-wpress.sh <caminho_wordpress> <caminho_ou_url_wpress>

WP_PATH="$1"
WPRESS_FILE="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$WP_PATH" ] || [ -z "$WPRESS_FILE" ]; then
    echo "Uso: $0 <caminho_wordpress> <caminho_ou_url_wpress>"
    exit 1
fi

backup_dir="$WP_PATH/wp-content/ai1wm-backups"
mkdir -p "$backup_dir"

# Baixar ou copiar o arquivo .wpress
if [[ "$WPRESS_FILE" =~ ^https?:// ]]; then
    echo "Baixando arquivo .wpress do link: $WPRESS_FILE"
    filename=$(basename "$WPRESS_FILE")
    wget "$WPRESS_FILE" -O "$backup_dir/$filename"
    wpress_local="$backup_dir/$filename"
else
    echo "Copiando arquivo .wpress: $WPRESS_FILE"
    filename=$(basename "$WPRESS_FILE")
    cp "$WPRESS_FILE" "$backup_dir/$filename"
    wpress_local="$backup_dir/$filename"
fi

# Verificar se o plugin está instalado
wp plugin is-installed all-in-one-wp-migration --path="$WP_PATH" --allow-root
if [ $? -ne 0 ]; then
    echo "Instalando plugin all-in-one-wp-migration..."
    wp plugin install all-in-one-wp-migration --activate --path="$WP_PATH" --allow-root
fi

# Verificar se a extensão Unlimited está disponível e instalar se necessário

# Verificar se a extensão Unlimited está instalada
wp plugin is-installed all-in-one-wp-migration-unlimited-extension --path="$WP_PATH" --allow-root
if [ $? -ne 0 ]; then
    echo "Atenção: Extensão Unlimited do All-in-One WP Migration não está instalada. O comando restore pode não funcionar para arquivos grandes."
fi

# Importar o backup
echo "Importando backup .wpress..."
cd "$WP_PATH"
wp ai1wm restore "$filename" --path="$WP_PATH" --allow-root --yes
