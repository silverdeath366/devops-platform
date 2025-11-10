# 🚀 Quick Start Guide

## 📦 Prerequisites

- Docker & Docker Compose
- Python 3.12+
- Make (optional but recommended)
- kubectl & Minikube (for Kubernetes deployment)

---

## ⚡ 60-Second Start

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd devops-platform

# 2. Quick start (setup + run)
make quickstart
```

That's it! Services are now running at:
- Auth: http://localhost:8001/health
- User: http://localhost:8002/health
- Task: http://localhost:8003/health
- Notification: http://localhost:8004/health

---

## 🐳 Docker Compose Options

### Option 1: Development (SQLite)
```bash
make docker-up
```

### Option 2: Production-like (PostgreSQL)
```bash
make docker-up-postgres
```

### Stop Services
```bash
make docker-down
```

---

## 🧪 Testing

```bash
# Run all tests
make test

# Test specific service
make test-service SERVICE=auth

# Run linters
make lint

# Format code
make format
```

---

## ☸️ Kubernetes Deployment

### Minikube
```bash
# Start Minikube
make minikube-start

# Deploy all services
make minikube-deploy

# Check status
make k8s-status

# View logs
make k8s-logs SERVICE=auth
```

### Manual Helm
```bash
# Deploy auth service
helm install auth helm/charts/auth

# Deploy all services
make k8s-deploy
```

---

## 🔄 CI/CD Setup

### 1. GitHub Secrets
Add these to your GitHub repository:
- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_PASSWORD` - Your Docker Hub token

### 2. Push Code
```bash
git add .
git commit -m "feat: initial setup"
git push origin main
```

The CI/CD pipeline will automatically:
- ✅ Run tests
- ✅ Lint code
- ✅ Build Docker images
- ✅ Scan for vulnerabilities
- ✅ Push to Docker Hub
- ✅ Trigger GitOps deployment

---

## 📊 Monitoring

### Health Checks
```bash
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:8004/health
```

### Metrics
```bash
curl http://localhost:8001/metrics
```

---

## 🔧 Common Commands

```bash
# Build all services
make build

# Build specific service
make build-service SERVICE=auth

# Push to registry
make push

# Clean up
make clean

# View help
make help
```

---

## 🌐 API Endpoints

### Auth Service (Port 8001)
```bash
# Register
curl -X POST http://localhost:8001/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "testpass123"}'

# Login
curl -X POST http://localhost:8001/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "testpass123"}'
```

### User Service (Port 8002)
```bash
# Create user
curl -X POST http://localhost:8002/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "username": "johndoe",
    "email": "john@example.com",
    "password": "secure123"
  }'

# List users
curl http://localhost:8002/users

# Get user
curl http://localhost:8002/users/1
```

### Task Service (Port 8003)
```bash
# Create task
curl -X POST http://localhost:8003/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Complete project",
    "description": "Finish the microservices platform",
    "user_id": 1
  }'

# List tasks
curl http://localhost:8003/tasks

# Update task
curl -X PATCH http://localhost:8003/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'
```

### Notification Service (Port 8004)
```bash
# Send notification
curl -X POST http://localhost:8004/notifications/notify \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "message": "Your task is complete!",
    "notification_type": "email"
  }'
```

---

## 🐛 Troubleshooting

### Services not starting?
```bash
# Check logs
make docker-logs

# Or for specific service
docker logs devops-auth
```

### Port conflicts?
Edit `.env` and change port numbers:
```bash
AUTH_PORT=9001
USER_PORT=9002
# etc.
```

### Database issues?
```bash
# Clean up and restart
make clean
make docker-down
make docker-up
```

### Kubernetes issues?
```bash
# Check pod status
kubectl get pods

# Check logs
kubectl logs <pod-name>

# Describe pod
kubectl describe pod <pod-name>
```

---

## 📚 Next Steps

1. **Read the full README**: [README.md](README.md)
2. **Configure for production**: Edit `.env.prod`
3. **Set up CI/CD**: Configure GitHub Actions
4. **Deploy to cloud**: Follow AWS/EKS guide in README
5. **Add monitoring**: Set up Prometheus/Grafana

---

## 🆘 Need Help?

- 📖 Full Documentation: [README.md](README.md)
- 🤝 Contributing: [CONTRIBUTING.md](CONTRIBUTING.md)
- 🐛 Issues: Open a GitHub issue
- 💬 Discussions: GitHub Discussions

---

**Happy coding! 🚀**

