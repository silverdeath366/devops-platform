#!/bin/bash
# Automated AWS deployment script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     AWS EKS Deployment Script              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not found"; exit 1; }
command -v eksctl >/dev/null 2>&1 || { echo "❌ eksctl not found"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not found"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ helm not found"; exit 1; }
echo -e "${GREEN}✅ All prerequisites found${NC}"
echo ""

# Configuration
read -p "Enter AWS Region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}
export AWS_REGION

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export CLUSTER_NAME="devops-platform-cluster"
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  AWS Account: $AWS_ACCOUNT_ID"
echo "  AWS Region: $AWS_REGION"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  ECR Registry: $ECR_REGISTRY"
echo ""

read -p "Continue with deployment? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Step 1: Create ECR Repositories
echo ""
echo -e "${YELLOW}Step 1: Creating ECR repositories...${NC}"
for service in auth user task notification; do
    echo "Creating ECR repo for $service..."
    aws ecr create-repository \
        --repository-name devops-platform/${service} \
        --region ${AWS_REGION} 2>/dev/null || echo "  Repository exists, skipping..."
done
echo -e "${GREEN}✅ ECR repositories ready${NC}"

# Step 2: Build and push images
echo ""
echo -e "${YELLOW}Step 2: Building and pushing Docker images...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ECR_REGISTRY}

for service in auth user task notification; do
    echo "Building $service..."
    docker build -t ${ECR_REGISTRY}/devops-platform/${service}:latest services/${service}
    echo "Pushing $service..."
    docker push ${ECR_REGISTRY}/devops-platform/${service}:latest
done
echo -e "${GREEN}✅ All images pushed to ECR${NC}"

# Step 3: Create EKS cluster
echo ""
echo -e "${YELLOW}Step 3: Creating EKS cluster (this takes ~15 minutes)...${NC}"
if eksctl get cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} 2>/dev/null; then
    echo "Cluster already exists, skipping creation..."
else
    eksctl create cluster \
        --name ${CLUSTER_NAME} \
        --region ${AWS_REGION} \
        --nodegroup-name standard-workers \
        --node-type t3.medium \
        --nodes 2 \
        --nodes-min 2 \
        --nodes-max 4 \
        --managed
fi
echo -e "${GREEN}✅ EKS cluster ready${NC}"

# Step 4: Create RDS database
echo ""
echo -e "${YELLOW}Step 4: Setting up RDS PostgreSQL...${NC}"
echo "Creating DB subnet group..."
aws rds create-db-subnet-group \
    --db-subnet-group-name devops-db-subnet \
    --db-subnet-group-description "DevOps Platform DB Subnet" \
    --subnet-ids $(aws ec2 describe-subnets --filters "Name=tag:aws:cloudformation:stack-name,Values=eksctl-${CLUSTER_NAME}-cluster" --query 'Subnets[*].SubnetId' --output text | tr '\t' ' ') \
    --region ${AWS_REGION} 2>/dev/null || echo "  Subnet group exists..."

echo "Creating RDS instance..."
aws rds create-db-instance \
    --db-instance-identifier devops-postgres \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 16.1 \
    --master-username devopsadmin \
    --master-user-password "ChangeMeInProduction123!" \
    --allocated-storage 20 \
    --db-subnet-group-name devops-db-subnet \
    --publicly-accessible \
    --region ${AWS_REGION} 2>/dev/null || echo "  DB instance exists..."

echo "Waiting for RDS to be available (this may take 5-10 minutes)..."
aws rds wait db-instance-available \
    --db-instance-identifier devops-postgres \
    --region ${AWS_REGION}
echo -e "${GREEN}✅ RDS database ready${NC}"

# Get RDS endpoint
export RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier devops-postgres \
    --region ${AWS_REGION} \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
echo "RDS Endpoint: $RDS_ENDPOINT"

# Step 5: Create Kubernetes secrets
echo ""
echo -e "${YELLOW}Step 5: Creating Kubernetes secrets...${NC}"
kubectl create namespace devops-platform 2>/dev/null || true
kubectl config set-context --current --namespace=devops-platform

# Create secrets
kubectl create secret generic auth-secret \
    --from-literal=DATABASE_URL="postgresql+asyncpg://devopsadmin:ChangeMeInProduction123!@${RDS_ENDPOINT}:5432/postgres" \
    --from-literal=JWT_SECRET="$(openssl rand -hex 32)" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic user-secret \
    --from-literal=DATABASE_URL="postgresql+asyncpg://devopsadmin:ChangeMeInProduction123!@${RDS_ENDPOINT}:5432/postgres" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic task-secret \
    --from-literal=DATABASE_URL="postgresql+asyncpg://devopsadmin:ChangeMeInProduction123!@${RDS_ENDPOINT}:5432/postgres" \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Secrets created${NC}"

# Step 6: Update Helm values for ECR
echo ""
echo -e "${YELLOW}Step 6: Updating Helm values for ECR...${NC}"
for service in auth user task notification; do
    sed -i.bak "s|repository:.*|repository: ${ECR_REGISTRY}/devops-platform/${service}|" helm/charts/${service}/values.yaml
done
echo -e "${GREEN}✅ Helm values updated${NC}"

# Step 7: Install ingress controller
echo ""
echo -e "${YELLOW}Step 7: Installing NGINX Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s 2>/dev/null || echo "Waiting for ingress..."
echo -e "${GREEN}✅ Ingress controller installed${NC}"

# Step 8: Deploy services with Helm
echo ""
echo -e "${YELLOW}Step 8: Deploying services with Helm...${NC}"
for service in auth user task notification; do
    echo "Deploying $service..."
    helm upgrade --install ${service} helm/charts/${service} \
        --namespace devops-platform \
        --create-namespace \
        --set image.tag=latest
done
echo -e "${GREEN}✅ All services deployed${NC}"

# Step 9: Get LoadBalancer DNS
echo ""
echo -e "${YELLOW}Step 9: Getting LoadBalancer information...${NC}"
echo "Waiting for LoadBalancer to be ready..."
sleep 30
export LB_DNS=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "LoadBalancer DNS: $LB_DNS"

# Final summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Deployment Complete! 🎉            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "  EKS Cluster: $CLUSTER_NAME"
echo "  Region: $AWS_REGION"
echo "  RDS Endpoint: $RDS_ENDPOINT"
echo "  LoadBalancer: $LB_DNS"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Configure DNS to point to: $LB_DNS"
echo "  2. Set up SSL with cert-manager"
echo "  3. Configure monitoring"
echo ""
echo -e "${YELLOW}To access services:${NC}"
echo "  kubectl get pods -n devops-platform"
echo "  kubectl get svc -n devops-platform"
echo "  kubectl logs -n devops-platform -l app=auth"
echo ""
echo -e "${YELLOW}To clean up:${NC}"
echo "  bash aws/cleanup-aws.sh"
echo ""

