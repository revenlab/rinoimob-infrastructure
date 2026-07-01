# Deploy em Produção: King Host VPS + Cloudflare

Este guia descreve o caminho recomendado para colocar o Rinoimob no ar usando:

- VPS na King Host
- Cloudflare como DNS, proxy e borda HTTPS
- Docker Compose de produção em `rinoimob-infrastructure`
- Nginx como origin interno atrás da Cloudflare

## Arquitetura

```text
Usuario
  -> Cloudflare
  -> VPS King Host :443
  -> Nginx Docker
  -> app / backend / website / files
```

Somente `80` e `443` devem ficar públicos na VPS.

Não exponha publicamente:

- Postgres
- Redis
- RabbitMQ
- SeaweedFS
- Evolution API

Esses serviços ficam apenas na rede privada do Docker Compose.

## 1. Preparar a VPS

Assumindo Ubuntu na VPS:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl ca-certificates ufw
```

Instale Docker e Docker Compose na VPS.

Depois, escolha uma pasta de deploy:

```bash
sudo mkdir -p /opt/rinoimob
sudo chown -R "$USER":"$USER" /opt/rinoimob
cd /opt/rinoimob
```

Clone os repositórios necessários:

```bash
git clone git@github.com:revenlab/rinoimob-backend.git
git clone git@github.com:revenlab/rinoimob-app.git
git clone git@github.com:revenlab/rinoimob-website.git
git clone git@github.com:revenlab/rinoimob-infrastructure.git
```

## 2. Configurar DNS na Cloudflare

Crie os registros DNS como proxied, com nuvem laranja:

```text
app.seudominio.com      A  IP_DA_VPS
api.seudominio.com      A  IP_DA_VPS
www.seudominio.com      A  IP_DA_VPS
files.seudominio.com    A  IP_DA_VPS
```

No painel da Cloudflare:

```text
SSL/TLS -> Overview -> Full (strict)
```

Use `Full (strict)`, não `Flexible`.

## 3. Criar certificado de origem Cloudflare

No painel da Cloudflare:

```text
SSL/TLS -> Origin Server -> Create Certificate
```

Inclua os hostnames usados pelo ambiente:

```text
app.seudominio.com
api.seudominio.com
www.seudominio.com
files.seudominio.com
```

Na VPS:

```bash
cd /opt/rinoimob/rinoimob-infrastructure
mkdir -p certs
nano certs/cloudflare-origin.pem
nano certs/cloudflare-origin.key
chmod 600 certs/cloudflare-origin.key
```

Cole o certificado em `cloudflare-origin.pem` e a chave privada em `cloudflare-origin.key`.

Esses arquivos não devem ser commitados.

## 4. Configurar `.env.prod`

Na VPS:

```bash
cd /opt/rinoimob/rinoimob-infrastructure
cp .env.prod.example .env.prod
nano .env.prod
```

Preencha os domínios:

```env
APP_DOMAIN=app.seudominio.com
API_DOMAIN=api.seudominio.com
WEBSITE_DOMAIN=www.seudominio.com
TENANT_WILDCARD_DOMAIN=*.seudominio.com
TENANT_BASE_DOMAIN=seudominio.com
FILES_DOMAIN=files.seudominio.com
```

Preencha as variáveis críticas:

```env
SPRING_PROFILE=prod
FRONTEND_URL=https://app.seudominio.com
CORS_ALLOWED_ORIGINS=https://app.seudominio.com,https://www.seudominio.com
PUBLIC_CORS_ALLOWED_ORIGINS=https://*

JWT_SECRET=trocar-por-um-segredo-forte-com-64-ou-mais-caracteres
DB_PASSWORD=trocar-por-senha-forte
RABBITMQ_PASSWORD=trocar-por-senha-forte
EVOLUTION_API_KEY=trocar-por-chave-forte

SUPPORT_ADMIN_EMAIL=suporte@seudominio.com
SUPPORT_ADMIN_PASSWORD=trocar-por-senha-forte
```

Configure Cloudflare for SaaS:

```env
CLOUDFLARE_API_TOKEN=token-com-permissao-de-custom-hostnames
CLOUDFLARE_ZONE_ID=zone-id-da-zona-principal
CLOUDFLARE_CUSTOM_HOSTNAME_TARGET=www.seudominio.com
```

Configure URLs públicas e internas:

```env
APP_VITE_API_URL=https://api.seudominio.com
APP_VITE_WS_URL=https://api.seudominio.com/ws

NUXT_PUBLIC_API_URL=https://api.seudominio.com
NUXT_PUBLIC_APP_URL=https://app.seudominio.com
NUXT_API_INTERNAL_URL=http://backend:39000

SEAWEEDFS_VOLUME_PUBLIC_URL=https://files.seudominio.com
```

Para sites de clientes em subdomínios como `cliente.seudominio.com`, crie no
Cloudflare um DNS wildcard proxied (`*.seudominio.com`) apontando para a VPS e
gere o Cloudflare Origin Certificate cobrindo também `*.seudominio.com`.

Configure integrações se forem usadas em produção:

```env
MAIL_HOST=smtp.resend.com
MAIL_PORT=587
MAIL_USERNAME=resend
MAIL_PASSWORD=

AI_PROVIDER=gemini
AI_GEMINI_API_KEY=

ABACATEPAY_API_KEY=
ABACATEPAY_WEBHOOK_SECRET=
ABACATEPAY_WEBHOOK_SIGNING_SECRET=
ABACATEPAY_PRODUCT_STARTER_ID=
ABACATEPAY_PRODUCT_PRIME_ID=
ABACATEPAY_PRODUCT_ULTIMATE_ID=
```

## 5. Configurar firewall

Configuração inicial:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

Depois que tudo estiver estável, restrinja `80` e `443` aos IPs oficiais da Cloudflare.

Lista oficial:

```text
https://www.cloudflare.com/ips/
```

## 6. Subir o ambiente

Na VPS:

```bash
cd /opt/rinoimob/rinoimob-infrastructure
docker compose --env-file .env.prod -f docker-compose.prod.yml config
docker compose --env-file .env.prod -f docker-compose.prod.yml build
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d
docker compose --env-file .env.prod -f docker-compose.prod.yml ps
```

Ver logs:

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml logs -f
```

Rebuild de um serviço:

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build backend
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build app
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build website
```

Parar sem apagar dados:

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml down
```

Nunca rode `down -v` em produção, porque isso remove volumes persistentes.

## 7. Smoke tests

Teste API:

```bash
curl -fsS https://api.seudominio.com/actuator/health
```

Teste app:

```bash
curl -fsS https://app.seudominio.com/health
```

Teste website:

```bash
curl -fsS https://www.seudominio.com/
```

Depois rode o smoke E2E no app:

```bash
cd /opt/rinoimob/rinoimob-app
npm run test:e2e:prod
```

Antes disso, configure as variáveis `E2E_*` com dados reais do ambiente.

## 8. Checklist antes de anunciar

- Cloudflare DNS com nuvem laranja.
- Cloudflare SSL/TLS em `Full (strict)`.
- Certificado Origin instalado em `certs/cloudflare-origin.pem`.
- Chave Origin instalada em `certs/cloudflare-origin.key`.
- `.env.prod` preenchido sem valores default.
- `SPRING_PROFILE=prod`.
- `JWT_SECRET` forte.
- `DB_PASSWORD` forte.
- `RABBITMQ_PASSWORD` forte.
- `EVOLUTION_API_KEY` forte.
- `CORS_ALLOWED_ORIGINS` só com domínios reais.
- `PUBLIC_CORS_ALLOWED_ORIGINS=https://*` para permitir sites públicos em domínios customizados.
- `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_ID` e `CLOUDFLARE_CUSTOM_HOSTNAME_TARGET` preenchidos.
- `docker compose ps` sem containers reiniciando.
- API health retornando `UP`.
- App abre em `https://app.seudominio.com`.
- Website abre em `https://www.seudominio.com`.
- Upload/listagem de imagens usa `https://files.seudominio.com`.
- Login funciona.
- Logout invalida sessão.
- Usuário de suporte inicial existe.
- Backup do Postgres planejado.

## 9. Backups mínimos

Antes de tráfego real, defina backup para:

- volume `postgres_data`
- volumes `seaweedfs_master_data` e `seaweedfs_volume_data`
- volume `evolution_data`

Exemplo de dump manual do Postgres:

```bash
docker exec rinoimob-postgres-prod pg_dump -U "$DB_USER" "$DB_NAME" > rinoimob-backup.sql
```

## 10. Referências

- Cloudflare Full strict: https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/
- Cloudflare Origin CA: https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/
- Restaurar IP real: https://developers.cloudflare.com/support/troubleshooting/restoring-visitor-ips/restoring-original-visitor-ips/
- IPs oficiais Cloudflare: https://www.cloudflare.com/ips/
