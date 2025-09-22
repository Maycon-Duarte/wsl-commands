# wsl-commands

Scripts para automação de ambientes WordPress, NGINX, banco de dados, hosts, SSL, DNS e importação de backups.

## Sumário
- [wp.sh](#wpsh)
- [db.sh](#dbsh)
- [nginx.sh](#nginxsh)
- [hosts.sh](#hostssh)
- [ssl.sh](#sslsh)
- [route53.sh](#route53sh)
- [import-wpress.sh](#import-wpresssh)

---

## wp.sh
Script principal para criar e remover sites WordPress.

- Instala WordPress, plugins padrão/adicionais, configura banco de dados, NGINX, hosts, SSL e DNS.
- Permite importar backup `.wpress` automaticamente.

**Exemplo de uso:**
```bash
./wp.sh add dominio.local [plugins_adicionais...] [caminho_ou_link_do_wpress]
./wp.sh remove dominio.local
```

## db.sh
Gerencia bancos de dados MySQL.

- Cria, remove e verifica existência de bancos de dados.

**Exemplo de uso:**
```bash
./db.sh create nome_do_banco
./db.sh remove nome_do_banco
./db.sh exists nome_do_banco
```

## nginx.sh
Gerencia domínios no NGINX.

- Adiciona e remove domínios, configura PHP, recarrega NGINX.

**Exemplo de uso:**
```bash
./nginx.sh add dominio.local
./nginx.sh remove dominio.local
```

## hosts.sh
Gerencia domínios no arquivo hosts do Windows.

- Adiciona e remove domínios no hosts para facilitar acesso local.

**Exemplo de uso:**
```bash
./hosts.sh add dominio.local
./hosts.sh remove dominio.local
```

## ssl.sh
Gerencia certificados SSL via Certbot.

- Adiciona e remove certificados SSL para domínios.

**Exemplo de uso:**
```bash
./ssl.sh add dominio.local
./ssl.sh remove dominio.local
```

## route53.sh
Gerencia registros DNS na AWS Route 53.

- Adiciona e remove registros DNS para domínios.

**Exemplo de uso:**
```bash
./route53.sh add dominio.local
./route53.sh remove dominio.local
```

## import-wpress.sh
Importa backups `.wpress` do All-in-One WP Migration via WP CLI.

- Baixa ou copia o arquivo `.wpress` para a pasta correta.
- Instala o plugin e extensão Unlimited se necessário.
- Restaura o backup automaticamente.

**Exemplo de uso:**
```bash
./import-wpress.sh /caminho/para/wordpress /caminho/ou/link/do/backup.wpress
```

---

## Importação automática de backup (.wpress)

Ao adicionar um novo site WordPress com o comando:

```bash
./wp.sh add dominio.local [plugins_adicionais...] [caminho_ou_link_do_wpress]
```

Se você passar o caminho local ou o link de um arquivo `.wpress` como último argumento, o script irá:
- Baixar ou copiar o arquivo para a pasta correta do WordPress
- Instalar o plugin All-in-One WP Migration e a extensão Unlimited (se disponível)
- Restaurar o backup automaticamente via WP CLI

**Exemplo:**
```bash
./wp.sh add exemplo.local elementor woocommerce https://meusite.com/backup.wpress
```

Se o restore não funcionar via WP CLI, o arquivo estará disponível no painel do WordPress em All-in-One WP Migration > Backups para restauração manual.
