# Rinoimob Infrastructure

Docker Compose configuration and infrastructure templates for the Rinoimob property management platform.

> `docker-compose.yml` is the local dependency stack. Use `docker-compose.prod.yml`
> for the application deployment path.

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+

## Services

The docker-compose stack includes:

- **PostgreSQL 15**: Main application database
  - Port: 5432
  - User: postgres
  - Password: pass (development)

- **Redis 7**: Caching and session store
  - Port: 6379

- **RabbitMQ 3.12**: Message broker
  - Port: 5672 (AMQP)
  - Port: 15672 (Management UI)
  - User: guest
  - Password: guest

## Quick Start

1. Copy `.env.example` to `.env`
2. Adjust environment variables as needed
3. Start services:
   ```bash
   docker-compose up -d
   ```

4. Verify services are healthy:
   ```bash
   docker-compose ps
   ```

## Common Commands

```bash
# Start services in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Remove volumes (caution: deletes data)
docker-compose down -v

# Validate configuration
docker-compose config
```

## Production Docker Compose

The production compose file builds and runs:

- `backend` — Spring Boot API on the private Docker network
- `app` — internal Vue/Vite app served by Nginx
- `website` — Nuxt 3 SSR public site
- `nginx` — public reverse proxy / Cloudflare origin
- `postgres`, `redis`, `rabbitmq`, `seaweedfs`, `evolution-api` — private dependencies

Only ports `80` and `443` are published by this compose file. Cloudflare should
proxy all public DNS records and connect to the origin through HTTPS using a
Cloudflare Origin Certificate mounted in `./certs`. Do not publish Postgres,
Redis, RabbitMQ, SeaweedFS master/volume or Evolution API directly to the
Internet.

Custom domains use the HTTPS default server in `nginx.prod.conf`, which routes
unknown hostnames to the public website. The backend public CORS policy allows
HTTPS custom domains only for `/api/v1/public/**`; authenticated app/API routes
remain restricted by `CORS_ALLOWED_ORIGINS`.

### First deploy

```bash
cp .env.prod.example .env.prod
# Fill every secret and real domain in .env.prod before continuing.
# Add Cloudflare Origin Certificate files:
#   certs/cloudflare-origin.pem
#   certs/cloudflare-origin.key

docker compose --env-file .env.prod -f docker-compose.prod.yml config
docker compose --env-file .env.prod -f docker-compose.prod.yml build
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d
docker compose --env-file .env.prod -f docker-compose.prod.yml ps
```

To validate the template without creating a real `.env.prod`, use:

```bash
RINOIMOB_ENV_FILE=.env.prod.example docker compose --env-file .env.prod.example -f docker-compose.prod.yml config
```

### Required DNS

Point these records to the production host before starting the reverse proxy:

- `APP_DOMAIN` → internal app, for example `app.example.com`
- `API_DOMAIN` → backend API, for example `api.example.com`
- `WEBSITE_DOMAIN` → public website, for example `www.example.com`
- `TENANT_WILDCARD_DOMAIN` → tenant public sites, for example `*.example.com`
- `TENANT_BASE_DOMAIN` → base used to resolve tenant subdomains, for example `example.com`
- `FILES_DOMAIN` → public property media, for example `files.example.com`

In Cloudflare, keep these records proxied. Set SSL/TLS encryption mode to
`Full (strict)`. The origin certificate must cover every configured hostname.
Set `CLOUDFLARE_CUSTOM_HOSTNAME_TARGET` to the hostname customers should CNAME
to, normally `WEBSITE_DOMAIN`.

For tenant subdomains such as `cliente.example.com`, create a proxied wildcard
DNS record (`*.example.com`) pointing to the production host and include the
wildcard hostname in the Cloudflare Origin Certificate mounted by Nginx.

The Nginx origin restores the visitor IP from `CF-Connecting-IP` when requests
come from Cloudflare IP ranges. Keep the Cloudflare IP list current and restrict
host firewall ingress for ports `80` and `443` to Cloudflare IP ranges whenever
possible:

- https://www.cloudflare.com/ips/
- https://developers.cloudflare.com/support/troubleshooting/restoring-visitor-ips/restoring-original-visitor-ips/

Tenant wildcard subdomains are handled by `TENANT_WILDCARD_DOMAIN`; arbitrary
customer-owned domains still use the HTTPS default server plus the configured
custom-hostname DNS/TLS strategy.

### Smoke checks

```bash
curl -fsS "https://${API_DOMAIN}/actuator/health"
curl -fsS "https://${APP_DOMAIN}/health"
curl -fsS "https://${WEBSITE_DOMAIN}/"
```

Then run the app smoke tests from `../rinoimob-app` with real production values:

```bash
npm run test:e2e:prod
```

### Operations

```bash
# Follow logs
docker compose --env-file .env.prod -f docker-compose.prod.yml logs -f

# Restart one service after an image rebuild
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build backend

# Stop the stack without deleting data
docker compose --env-file .env.prod -f docker-compose.prod.yml down
```

Back up `postgres_data`, `seaweedfs_*_data` and `evolution_data` before major
deployments. Never run `down -v` in production unless the intent is to delete
persistent data.

## Database Access

```bash
# Connect to PostgreSQL
docker exec -it rinoimob-postgres psql -U user -d rinoimob

# Run SQL script
docker exec -i rinoimob-postgres psql -U user -d rinoimob < scripts/init-db.sql
```

## RabbitMQ Management

Access the management UI at: http://localhost:15672

## Environment Variables

See `.env.example` for all available configuration options.

## File Structure

```
├── docker-compose.yml      # Main compose configuration
├── .env.example            # Example environment variables
├── scripts/
│   └── init-db.sql        # Database initialization script
└── k8s/                    # Kubernetes manifests (future)
```


Infrastructure as Code - Docker, Kubernetes, and Terraform configurations.

## Tech Stack
- Docker
- Docker Compose
- Kubernetes
- Terraform
- GitHub Actions

## Project Structure
- `docker/` - Dockerfile and docker-compose configurations
- `k8s/` - Kubernetes manifests
- `terraform/` - Terraform Infrastructure as Code
- `scripts/` - Deployment and utility scripts

## Getting Started

### Local Development (Docker Compose)
```bash
docker-compose up -d
```

### Cloud Deployment (Kubernetes)
```bash
kubectl apply -f k8s/
```

### Infrastructure as Code (Terraform)
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Documentation
See [../rinoimob-docs](../rinoimob-docs) for detailed deployment guides.

## Issues
All infrastructure tasks are tracked in [.projects](https://github.com/revenlab/.projects/issues?q=label%3Ainfra).
