# 🚀 Deployment Guide

Complete guide for deploying the DevOps Microservices Platform to various environments.

---

## 📋 Table of Contents

- [Local Development](#local-development)
- [Docker Compose](#docker-compose)
- [Kubernetes (Minikube)](#kubernetes-minikube)
- [AWS EKS](#aws-eks)
- [Argo CD GitOps](#argo-cd-gitops)
- [Production Checklist](#production-checklist)

---

## 🖥️ Local Development

### Setup

```bash
# Clone and setup
git clone <repo-url>
cd devops-platform
make setup
```

### Run Individual Services

```bash
# Terminal 1 - Auth Service
cd services/auth
uvicorn app.main:app --reload --port 8001

# Terminal 2 - User Service
cd services/user
uvicorn app.main:app --reload --port 8002

# Terminal 3 - Task Service
cd services/task
uvicorn app.main:app --reload --port 8003

# Terminal 4 - Notification Service
cd services/notification
uvicorn app.main:app --reload --port 8004
```

---

## 🐳 Docker Compose

### Development Mode (SQLite)

```bash
# Start services
docker-compose --profile dev up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Production Mode (PostgreSQL)

```bash
# Start with PostgreSQL
docker-compose --profile prod --profile postgres up -d

# Check health
docker-compose ps

# Stop
docker-compose --profile prod --profile postgres down
```

### Environment Variables

Create `.env` file:
```bash
cp .env.example .env
nano .env
```

Key variables:
```bash
ENVIRONMENT=production
DEBUG=false
POSTGRES_USER=devops_user
POSTGRES_PASSWORD=secure_password
```

---

## ☸️ Kubernetes (Minikube)

### 1. Start Minikube

```bash
# Start with appropriate resources
minikube start --cpus=4 --memory=8192 --driver=docker

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server
```

### 2. Build Images

```bash
# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Build all services
make build
```

### 3. Create Namespace

```bash
kubectl create namespace devops-platform
kubectl config set-context --current --namespace=devops-platform
```

### 4. Create Secrets

```bash
# Auth secrets
kubectl create secret generic auth-secret \
  --from-literal=DATABASE_URL='postgresql+asyncpg://user:pass@postgres:5432/auth_db' \
  --from-literal=JWT_SECRET='your-jwt-secret'

# User secrets
kubectl create secret generic user-secret \
  --from-literal=DATABASE_URL='postgresql+asyncpg://user:pass@postgres:5432/user_db'

# Task secrets
kubectl create secret generic task-secret \
  --from-literal=DATABASE_URL='postgresql+asyncpg://user:pass@postgres:5432/task_db'
```

### 5. Deploy Services

```bash
# Deploy all services
make k8s-deploy

# Or deploy individually
helm install auth helm/charts/auth --namespace devops-platform
helm install user helm/charts/user --namespace devops-platform
helm install task helm/charts/task --namespace devops-platform
helm install notification helm/charts/notification --namespace devops-platform
```

### 6. Verify Deployment

```bash
# Check pods
kubectl get pods

# Check services
kubectl get svc

# Check ingress
kubectl get ingress

# View logs
kubectl logs -l app=auth --tail=50
```

### 7. Access Services

```bash
# Get Minikube IP
minikube ip

# Add to /etc/hosts
echo "$(minikube ip) auth.devops.local user.devops.local task.devops.local notification.devops.local" | sudo tee -a /etc/hosts

# Access services
curl http://auth.devops.local/health
curl http://user.devops.local/health
curl http://task.devops.local/health
curl http://notification.devops.local/health
```

---

## ☁️ AWS EKS

### Prerequisites

- AWS CLI configured
- eksctl installed
- kubectl installed
- Helm 3 installed

### 1. Create EKS Cluster

```bash
# Create cluster (takes ~15 minutes)
eksctl create cluster \
  --name devops-platform \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed

# Verify cluster
kubectl get nodes
```

### 2. Create RDS PostgreSQL Database

```bash
# Create DB subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name devops-db-subnet \
  --db-subnet-group-description "Subnet group for DevOps Platform" \
  --subnet-ids subnet-xxx subnet-yyy

# Create PostgreSQL instance
aws rds create-db-instance \
  --db-instance-identifier devops-postgres \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16.1 \
  --master-username devopsadmin \
  --master-user-password 'YourSecurePassword' \
  --allocated-storage 20 \
  --db-subnet-group-name devops-db-subnet \
  --vpc-security-group-ids sg-xxxxx

# Wait for DB to be available
aws rds wait db-instance-available --db-instance-identifier devops-postgres

# Get endpoint
aws rds describe-db-instances \
  --db-instance-identifier devops-postgres \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

### 3. Create ECR Repositories

```bash
# Authenticate to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# Create repositories
for service in auth user task notification; do
  aws ecr create-repository \
    --repository-name devops-platform/${service} \
    --region us-east-1
done
```

### 4. Build and Push Images

```bash
# Set variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1
export ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push
for service in auth user task notification; do
  docker build -t ${ECR_REGISTRY}/devops-platform/${service}:latest services/${service}
  docker push ${ECR_REGISTRY}/devops-platform/${service}:latest
done
```

### 5. Create Kubernetes Secrets

```bash
# Get RDS endpoint
export RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier devops-postgres \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

# Create secrets
kubectl create secret generic auth-secret \
  --from-literal=DATABASE_URL="postgresql+asyncpg://devopsadmin:YourSecurePassword@${RDS_ENDPOINT}:5432/auth_db" \
  --from-literal=JWT_SECRET='your-production-jwt-secret'

kubectl create secret generic user-secret \
  --from-literal=DATABASE_URL="postgresql+asyncpg://devopsadmin:YourSecurePassword@${RDS_ENDPOINT}:5432/user_db"

kubectl create secret generic task-secret \
  --from-literal=DATABASE_URL="postgresql+asyncpg://devopsadmin:YourSecurePassword@${RDS_ENDPOINT}:5432/task_db"
```

### 6. Update Helm Values for EKS

```bash
# Update image repository in values files
for service in auth user task notification; do
  sed -i "s|repository:.*|repository: ${ECR_REGISTRY}/devops-platform/${service}|" \
    helm/charts/${service}/values.yaml
done
```

### 7. Install Ingress Controller

```bash
# Install nginx-ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml

# Wait for LoadBalancer
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Get LoadBalancer DNS
kubectl get svc -n ingress-nginx
```

### 8. Deploy Services

```bash
# Deploy with Helm
make k8s-deploy

# Verify
kubectl get pods
kubectl get svc
kubectl get ingress
```

### 9. Configure DNS

```bash
# Get LoadBalancer DNS
export LB_DNS=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Create Route53 records or update your DNS
# Point your domains to the LoadBalancer DNS
# Example:
# auth.yourdomain.com -> CNAME -> ${LB_DNS}
# user.yourdomain.com -> CNAME -> ${LB_DNS}
```

### 10. Enable SSL with cert-manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create Let's Encrypt issuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

---

## 🔄 Argo CD GitOps

### 1. Install Argo CD

```bash
# Create namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### 2. Access Argo CD UI

```bash
# Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 9000:443

# Open browser
# https://localhost:9000
# Username: admin
# Password: <from above command>
```

### 3. Create Applications

```bash
# Apply Argo CD applications
kubectl apply -f apps/

# Verify
kubectl get applications -n argocd
```

### 4. Configure Repository

```bash
# Add your Git repository
argocd repo add https://github.com/yourusername/devops-platform.git \
  --username your-username \
  --password your-token
```

### 5. Sync Applications

```bash
# Sync all applications
argocd app sync auth
argocd app sync user
argocd app sync task
argocd app sync notification

# Or sync all
argocd app sync --all
```

---

## ✅ Production Checklist

### Security
- [ ] Change all default passwords
- [ ] Use strong JWT secrets
- [ ] Enable HTTPS/TLS
- [ ] Configure CORS properly
- [ ] Set up network policies
- [ ] Enable pod security policies
- [ ] Use secrets manager (AWS Secrets Manager/Vault)

### Database
- [ ] Use managed database (RDS/Cloud SQL)
- [ ] Enable automated backups
- [ ] Set up replication
- [ ] Configure connection pooling
- [ ] Enable encryption at rest
- [ ] Set up monitoring

### Monitoring & Logging
- [ ] Set up Prometheus
- [ ] Configure Grafana dashboards
- [ ] Enable log aggregation (ELK/CloudWatch)
- [ ] Set up alerting
- [ ] Configure health checks
- [ ] Enable distributed tracing

### Performance
- [ ] Configure autoscaling (HPA)
- [ ] Set resource limits
- [ ] Enable caching
- [ ] Configure CDN
- [ ] Optimize database queries

### High Availability
- [ ] Run multiple replicas
- [ ] Configure pod disruption budgets
- [ ] Use anti-affinity rules
- [ ] Set up load balancing
- [ ] Configure graceful shutdown

### Disaster Recovery
- [ ] Document recovery procedures
- [ ] Set up automated backups
- [ ] Test restore procedures
- [ ] Configure multi-region deployment
- [ ] Set up disaster recovery plan

### Compliance
- [ ] Enable audit logging
- [ ] Implement data retention policies
- [ ] Configure GDPR compliance
- [ ] Set up access controls
- [ ] Document security procedures

---

## 🆘 Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Database connection issues

```bash
# Test database connectivity
kubectl run -it --rm debug --image=postgres:16 --restart=Never -- \
  psql postgresql://user:pass@host:5432/dbname

# Check secrets
kubectl get secret auth-secret -o yaml
```

### Ingress not working

```bash
# Check ingress
kubectl describe ingress

# Check ingress controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://auth.devops.local/health
```

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

---

**Good luck with your deployment! 🚀**

