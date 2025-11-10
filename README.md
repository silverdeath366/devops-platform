# 🚀 DevOps Microservices Platform

A **production-grade**, cloud-native microservices platform built with modern DevOps best practices. Designed for real-world deployment, interviews, and portfolio demonstrations.

[![CI/CD](https://github.com/yourusername/devops-platform/actions/workflows/ci-cd.yaml/badge.svg)](https://github.com/yourusername/devops-platform/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [Development](#-development)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [CI/CD](#-cicd)
- [Monitoring](#-monitoring)
- [Cloud Deployment](#-cloud-deployment)
- [Project Structure](#-project-structure)

---

## 🏗️ Architecture

This platform consists of **4 microservices**:

| Service | Purpose | Port | Tech Stack |
|---------|---------|------|------------|
| **Auth** | Authentication & JWT tokens | 8001 | FastAPI, PostgreSQL, JWT |
| **User** | User profile management | 8002 | FastAPI, PostgreSQL |
| **Task** | Task/TODO management | 8003 | FastAPI, PostgreSQL |
| **Notification** | Multi-channel notifications | 8004 | FastAPI |

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         API Gateway                          │
│                      (Nginx Ingress)                         │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
    ┌─────▼─────┐      ┌─────▼─────┐      ┌─────▼─────┐
    │   Auth    │      │   User    │      │   Task    │
    │  Service  │──────│  Service  │──────│  Service  │
    └───────────┘      └───────────┘      └───────────┘
          │                   │                   │
          │                   │                   │
    ┌─────▼──────────────────▼──────────────────▼─────┐
    │            PostgreSQL Database                   │
    └─────────────────────────────────────────────────┘
                              │
                      ┌───────▼────────┐
                      │  Notification  │
                      │    Service     │
                      └────────────────┘
```

---

## ✨ Features

### 🔧 Microservices
- ✅ **Modular FastAPI applications** with clean architecture
- ✅ **Pydantic v2** for request/response validation
- ✅ **SQLAlchemy 2.0** with async support
- ✅ **PostgreSQL** for production, SQLite for development
- ✅ **Health checks** (`/health`, `/healthz`, `/ready`)
- ✅ **Prometheus metrics** (`/metrics`)
- ✅ **OpenAPI/Swagger** documentation

### 🐳 Docker & Containerization
- ✅ **Multi-stage Dockerfiles** for optimized images
- ✅ **Non-root users** for security
- ✅ **Health checks** built into containers
- ✅ **Docker Compose** with profiles (dev/test/prod)
- ✅ **PostgreSQL** integration

### ☸️ Kubernetes & Helm
- ✅ **Individual Helm charts** per service
- ✅ **Horizontal Pod Autoscaling** (HPA)
- ✅ **Pod Disruption Budgets** (PDB)
- ✅ **Resource limits** and requests
- ✅ **Liveness/Readiness probes**
- ✅ **Service Accounts** and RBAC
- ✅ **Ingress** with TLS support
- ✅ **ServiceMonitor** for Prometheus

### 🔄 CI/CD
- ✅ **GitHub Actions** workflows
- ✅ **Code linting** (Ruff, Black, MyPy)
- ✅ **Unit & integration tests** with coverage
- ✅ **Docker image building** and pushing
- ✅ **Trivy security scanning**
- ✅ **GitOps** with Argo CD auto-sync
- ✅ **Dependabot** for dependency updates

### 📊 Observability
- ✅ **Prometheus metrics** for all services
- ✅ **Structured logging**
- ✅ **Health check endpoints**
- ✅ **Service monitoring** ready

### ☁️ Cloud-Ready
- ✅ **AWS EKS/ECS** compatible
- ✅ **ECR** registry support
- ✅ **RDS PostgreSQL** support
- ✅ **AWS Secrets Manager** integration ready
- ✅ **Environment-based configuration**

---

## 🛠️ Tech Stack

### Backend
- **Python 3.12**
- **FastAPI 0.115** - Modern web framework
- **Pydantic v2** - Data validation
- **SQLAlchemy 2.0** - ORM with async support
- **PostgreSQL 16** / SQLite - Databases
- **Uvicorn** - ASGI server
- **Gunicorn** - Production WSGI server

### DevOps & Infrastructure
- **Docker & Docker Compose** - Containerization
- **Kubernetes** - Orchestration
- **Helm 3** - Package management
- **Argo CD** - GitOps continuous delivery
- **Minikube** - Local Kubernetes
- **GitHub Actions** - CI/CD pipelines
- **Trivy** - Security scanning
- **Prometheus** - Metrics collection

### Development Tools
- **Pytest** - Testing framework
- **Ruff** - Fast Python linter
- **Black** - Code formatter
- **MyPy** - Static type checker
- **Make** - Build automation

---

## ⚡ Quick Start

### Prerequisites
- Docker & Docker Compose
- Python 3.12+
- Make (optional but recommended)

### 1. Clone & Setup

```bash
git clone https://github.com/yourusername/devops-platform.git
cd devops-platform
make setup
```

### 2. Start Services

```bash
# With Docker Compose (SQLite)
make docker-up

# With PostgreSQL
make docker-up-postgres
```

### 3. Verify Services

```bash
curl http://localhost:8001/health  # Auth
curl http://localhost:8002/health  # User
curl http://localhost:8003/health  # Task
curl http://localhost:8004/health  # Notification
```

---

## 💻 Development

### Environment Setup

```bash
# Install dependencies
make install-dev

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
nano .env
```

### Running Individual Services

```bash
# Run auth service
cd services/auth
uvicorn app.main:app --reload --port 8001

# Run with different environments
ENVIRONMENT=development uvicorn app.main:app --reload
```

### Code Quality

```bash
# Format code
make format

# Run linters
make lint

# Run tests
make test

# Test specific service
make test-service SERVICE=auth
```

---

## 🧪 Testing

### Run All Tests

```bash
make test
```

### Run Service-Specific Tests

```bash
cd services/auth
pytest tests/ -v --cov=app --cov-report=html
```

### Test Coverage

```bash
# Generate coverage report
cd services/auth
pytest tests/ --cov=app --cov-report=html
open htmlcov/index.html
```

---

## 🚀 Deployment

### Docker Compose (Development)

```bash
# Start all services
docker-compose --profile dev up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Kubernetes (Minikube)

```bash
# Start Minikube
make minikube-start

# Deploy all services
make k8s-deploy

# Check status
make k8s-status

# View logs
make k8s-logs SERVICE=auth
```

### Helm (Manual Deployment)

```bash
# Deploy individual service
helm install auth helm/charts/auth \
  --namespace devops \
  --create-namespace

# Upgrade deployment
helm upgrade auth helm/charts/auth

# Uninstall
helm uninstall auth
```

---

## 🔄 CI/CD

### GitHub Actions Workflows

The platform includes comprehensive CI/CD pipelines:

1. **Code Quality Check**
   - Linting (Ruff, Black)
   - Type checking (MyPy)
   - Unit tests with coverage

2. **Build & Scan**
   - Docker image building
   - Security scanning (Trivy)
   - Push to Docker Hub/ECR

3. **GitOps Deployment**
   - Update Helm values
   - Argo CD auto-sync
   - Automated rollout

### Setting Up CI/CD

1. **Add GitHub Secrets:**
   ```
   DOCKER_USERNAME - Docker Hub username
   DOCKER_PASSWORD - Docker Hub password/token
   ```

2. **Configure Argo CD:**
   ```bash
   make argocd-install
   make argocd-ui
   ```

3. **Create Argo CD Applications:**
   ```bash
   kubectl apply -f apps/
   ```

---

## 📊 Monitoring

### Prometheus Metrics

Each service exposes metrics at `/metrics`:

```bash
curl http://localhost:8001/metrics
```

### Available Metrics

- `{service}_requests_total` - Total requests count
- `{service}_uptime_seconds` - Service uptime
- `{service}_info` - Service metadata

### Health Checks

- `/health` - General health check
- `/healthz` - Kubernetes liveness probe
- `/ready` - Kubernetes readiness probe

---

## ☁️ Cloud Deployment (AWS)

### Quick AWS Deployment

```bash
# Automated deployment (recommended)
bash aws/deploy-to-aws.sh
```

This will:
1. Create ECR repositories
2. Build and push images
3. Create EKS cluster
4. Set up RDS PostgreSQL
5. Deploy all services with Helm
6. Configure ingress and load balancer

### Manual AWS Deployment

#### Option 1: Using Make Commands

```bash
# 1. Login and create ECR repositories
make aws-login
make aws-create-repos

# 2. Build and push to ECR
make aws-build-push

# 3. Update Helm charts for ECR
make aws-update-helm

# 4. Deploy to existing EKS cluster
make k8s-deploy
```

#### Option 2: Using Terraform

```bash
cd aws/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

terraform init
terraform plan
terraform apply
```

#### Option 3: Using CloudFormation

```bash
aws cloudformation create-stack \
  --stack-name devops-platform \
  --template-body file://aws/cloudformation/eks-cluster.yaml \
  --capabilities CAPABILITY_IAM
```

### Push Images to ECR

```bash
# Automated script
bash scripts/push-to-ecr.sh

# Or manually
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REGISTRY}

docker build -t ${ECR_REGISTRY}/devops-platform/auth:latest services/auth
docker push ${ECR_REGISTRY}/devops-platform/auth:latest
```

### Environment Variables for Production

```bash
# Database (RDS)
export AUTH_DATABASE_URL="postgresql+asyncpg://user:pass@rds-endpoint:5432/auth_db"

# AWS Secrets Manager
export JWT_SECRET=$(aws secretsmanager get-secret-value --secret-id jwt-secret --query SecretString --output text)

# Enable production mode
export ENVIRONMENT=production
export DEBUG=false
```

### AWS Cleanup

```bash
# Remove all AWS resources
bash aws/cleanup-aws.sh

# Or with Make
make aws-cleanup
```

### Cost Estimate

- **EKS Cluster**: ~$73/month
- **RDS db.t3.micro**: ~$15/month
- **ALB**: ~$20/month
- **ECR**: ~$1/month
- **Total**: ~$109/month

For detailed AWS deployment guide, see [aws/README.md](aws/README.md)

---

## 📁 Project Structure

```
devops-platform/
├── .github/
│   └── workflows/          # CI/CD pipelines
│       ├── ci-cd.yaml
│       └── pr-checks.yaml
├── services/
│   ├── auth/
│   │   ├── app/
│   │   │   ├── main.py
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   ├── models.py
│   │   │   ├── schemas.py
│   │   │   └── routers/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── user/
│   ├── task/
│   └── notification/
├── helm/
│   └── charts/
│       ├── auth/
│       │   ├── Chart.yaml
│       │   ├── values.yaml
│       │   └── templates/
│       ├── user/
│       ├── task/
│       └── notification/
├── k8s/
│   └── secrets/            # ConfigMaps and Secrets
├── apps/                   # Argo CD app manifests
├── scripts/                # Utility scripts
├── docker-compose.yaml     # Docker Compose config
├── Makefile               # Development automation
└── README.md
```

---

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Environment (dev/staging/prod) | `development` |
| `DEBUG` | Enable debug mode | `false` |
| `DATABASE_URL` | Database connection string | SQLite |
| `JWT_SECRET` | JWT signing secret | - |
| `CORS_ORIGINS` | Allowed CORS origins | `["*"]` |

### Database Configuration

**Development (SQLite):**
```bash
DATABASE_URL=sqlite+aiosqlite:///./app.db
```

**Production (PostgreSQL):**
```bash
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/dbname
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test updates
- `chore:` Build/config changes

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- FastAPI for the excellent web framework
- The Kubernetes community
- Argo CD team for GitOps tooling

---

## 📞 Contact & Support

- **Author:** Your Name
- **GitHub:** [@yourusername](https://github.com/yourusername)
- **LinkedIn:** [Your Profile](https://linkedin.com/in/yourprofile)

---

## 🎯 Roadmap

- [ ] Add OpenTelemetry tracing
- [ ] Implement API gateway
- [ ] Add WebSocket support
- [ ] Integrate with AWS Secrets Manager
- [ ] Add Grafana dashboards
- [ ] Implement rate limiting
- [ ] Add API versioning

---

**⭐ If you find this project useful, please give it a star!**
