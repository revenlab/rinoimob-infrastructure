# Rinoimob Infrastructure

Docker Compose configuration and infrastructure templates for the Rinoimob property management platform.

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+

## Services

The docker-compose stack includes:

- **PostgreSQL 15**: Main application database
  - Port: 5432
  - User: postgres
  - Password: postgres_dev (development)

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

## Database Access

```bash
# Connect to PostgreSQL
docker exec -it rinoimob-postgres psql -U postgres -d rinoimob

# Run SQL script
docker exec -i rinoimob-postgres psql -U postgres -d rinoimob < scripts/init-db.sql
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
