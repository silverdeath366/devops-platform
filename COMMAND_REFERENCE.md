# 🎯 Quick Command Reference Card

## 🚀 Testing Commands (Run These Now!)

```bash
# Quick test (30 seconds) - Recommended first!
bash quick-test.sh

# All features (1 minute) - Comprehensive validation
bash test-all-features.sh

# With PostgreSQL (2 minutes) - Production-like
bash scripts/test-with-postgres.sh

# Full comprehensive (3 minutes) - Everything
bash test-everything.sh

# Ultimate test suite (5 minutes) - All scenarios
bash TEST_EVERYTHING_NOW.sh
```

---

## 🐳 Docker Commands

```bash
# Start (SQLite - development)
docker compose -p devops-platform --profile dev up -d

# Start (PostgreSQL - production-like)  
docker compose -p devops-platform --profile dev --profile postgres up -d

# Stop
docker compose -p devops-platform down

# View logs
docker compose -p devops-platform logs -f

# Restart one service
docker compose -p devops-platform restart auth

# Rebuild and restart
docker compose -p devops-platform up -d --build
```

---

## ⚡ Make Commands

```bash
# Quick start (everything automated)
make quickstart

# Development
make setup          # Initial setup
make install-dev    # Install dependencies
make lint          # Run linters
make format        # Format code
make test          # Run all tests

# Docker
make build         # Build all images
make push          # Push to registry
make docker-up     # Start services
make docker-down   # Stop services

# Kubernetes
make k8s-deploy    # Deploy to K8s
make k8s-status    # Check status
make k8s-logs SERVICE=auth  # View logs

# AWS
make aws-login           # Login to ECR
make aws-create-repos    # Create ECR repos
make aws-build-push      # Build & push to ECR
make aws-deploy-full     # Full AWS deployment

# Cleanup
make clean         # Clean local files
make clean-docker  # Clean Docker resources

# Help
make help          # Show all commands
```

---

## ☸️ Kubernetes Commands

```bash
# Minikube
make minikube-start
make minikube-deploy
kubectl get pods
kubectl get svc

# Deploy services
helm install auth helm/charts/auth
helm install user helm/charts/user
helm install task helm/charts/task
helm install notification helm/charts/notification

# Check status
kubectl get pods -n devops-platform
kubectl get svc -n devops-platform
kubectl get ingress -n devops-platform

# View logs
kubectl logs -n devops-platform -l app=auth
kubectl logs -n devops-platform -f deployment/auth

# Delete
helm uninstall auth user task notification
```

---

## ☁️ AWS Commands

```bash
# Full automated deployment
bash aws/deploy-to-aws.sh

# Step by step
make aws-login
make aws-create-repos
make aws-build-push
make aws-update-helm
make k8s-deploy

# Or with scripts
bash scripts/push-to-ecr.sh

# Cleanup (WARNING: Deletes everything!)
bash aws/cleanup-aws.sh
```

---

## 🧪 Testing Commands

```bash
# Quick health check
for port in 8001 8002 8003 8004; do curl http://localhost:$port/health; done

# Test all metrics
for port in 8001 8002 8003 8004; do curl http://localhost:$port/metrics; done

# Test auth API
curl -X POST http://localhost:8001/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}'

# Test user API
curl -X POST http://localhost:8002/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","username":"test","email":"test@test.com","password":"test"}'

# Test task API
curl -X POST http://localhost:8003/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"Test","user_id":1}'

# Test notification API
curl -X POST http://localhost:8004/notifications/notify \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"message":"Test","notification_type":"email"}'
```

---

## 📊 Monitoring Commands

```bash
# Install monitoring
bash scripts/install-monitoring.sh

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open http://localhost:9090

# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
# Open http://localhost:3000 (admin/admin)

# Check metrics
curl http://localhost:8001/metrics
```

---

## 🔧 Troubleshooting Commands

```bash
# Check container status
docker ps -a

# View all logs
docker compose -p devops-platform logs

# View specific service logs
docker logs devops-auth
docker logs devops-user
docker logs devops-task
docker logs devops-notification

# Check Kubernetes pods
kubectl get pods -n devops-platform
kubectl describe pod <pod-name> -n devops-platform

# Clean restart
docker compose -p devops-platform down
docker compose -p devops-platform --profile dev up -d --build

# Full cleanup
make clean
make clean-docker
```

---

## 🎯 One-Liners

```bash
# Health check all services
for p in 8001 8002 8003 8004; do echo "Port $p:"; curl -s http://localhost:$p/health | jq .status; done

# Metrics from all services
for p in 8001 8002 8003 8004; do echo "=== Port $p ==="; curl -s http://localhost:$p/metrics | head -n 10; done

# Restart everything fresh
docker compose -p devops-platform down && docker compose -p devops-platform --profile dev up -d --build && sleep 15 && bash quick-test.sh

# Push all to ECR
make aws-login && make aws-build-push

# Deploy everything to K8s
make k8s-deploy && kubectl get pods -n devops-platform

# Full test suite
bash test-all-features.sh && bash scripts/test-with-postgres.sh
```

---

## 🔥 Most Used Commands

```bash
# Daily development
make docker-up
make test
make docker-down

# Before committing
make format
make lint
make test

# Quick validation
bash quick-test.sh

# Deploy to staging
make minikube-deploy

# Deploy to production
bash aws/deploy-to-aws.sh
```

---

## 📖 Where to Find More

- **All commands:** `make help`
- **Full docs:** `INDEX.md`
- **Quick start:** `START_HERE.md`
- **Testing guide:** `RUN_ALL_TESTS.md`
- **AWS guide:** `aws/README.md`

---

**Keep this reference handy!** 📌

Save it for quick lookups during development and deployment.

