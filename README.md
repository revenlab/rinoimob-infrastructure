# Rinoimob Infrastructure

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
