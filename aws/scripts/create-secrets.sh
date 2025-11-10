#!/bin/bash
# Create AWS Secrets Manager secrets and Kubernetes secrets

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-devops-platform-eks}
DB_ENDPOINT=${DB_ENDPOINT}
DB_USERNAME=${DB_USERNAME:-devopsadmin}
DB_PASSWORD=${DB_PASSWORD}

echo "🔐 Creating Secrets"
echo "=================="
echo ""

if [ -z "$DB_ENDPOINT" ]; then
    echo "❌ DB_ENDPOINT not set. Please set it first:"
    echo "   export DB_ENDPOINT=<your-rds-endpoint>"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "❌ DB_PASSWORD not set. Please set it first:"
    echo "   export DB_PASSWORD=<your-db-password>"
    exit 1
fi

# Generate JWT secret
JWT_SECRET=$(openssl rand -base64 32)

echo "1. Creating AWS Secrets Manager secrets..."
echo ""

# Create JWT secret
aws secretsmanager create-secret \
    --name devops-platform/jwt-secret \
    --description "JWT secret for auth service" \
    --secret-string "$JWT_SECRET" \
    --region $AWS_REGION \
    2>/dev/null || \
    aws secretsmanager update-secret \
        --secret-id devops-platform/jwt-secret \
        --secret-string "$JWT_SECRET" \
        --region $AWS_REGION
echo "  ✅ JWT secret created"

# Create database credentials
aws secretsmanager create-secret \
    --name devops-platform/database-credentials \
    --description "Database credentials" \
    --secret-string "{\"username\":\"${DB_USERNAME}\",\"password\":\"${DB_PASSWORD}\",\"endpoint\":\"${DB_ENDPOINT}\"}" \
    --region $AWS_REGION \
    2>/dev/null || \
    aws secretsmanager update-secret \
        --secret-id devops-platform/database-credentials \
        --secret-string "{\"username\":\"${DB_USERNAME}\",\"password\":\"${DB_PASSWORD}\",\"endpoint\":\"${DB_ENDPOINT}\"}" \
        --region $AWS_REGION
echo "  ✅ Database credentials created"

echo ""
echo "2. Creating Kubernetes secrets..."
echo ""

# Make sure we're connected to the right cluster
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Create namespace
kubectl create namespace devops-platform 2>/dev/null || true

# Create auth secret
kubectl create secret generic auth-secret \
    --from-literal=DATABASE_URL="postgresql+asyncpg://${DB_USERNAME}:${DB_PASSWORD}@${DB_ENDPOINT}:5432/auth_db" \
    --from-literal=JWT_SECRET="$JWT_SECRET" \
    --namespace devops-platform \
    --dry-run=client -o yaml | kubectl apply -f -
echo "  ✅ auth-secret created"

# Create user secret
kubectl create secret generic user-secret \
    --from-literal=DATABASE_URL="postgresql+asyncpg://${DB_USERNAME}:${DB_PASSWORD}@${DB_ENDPOINT}:5432/user_db" \
    --namespace devops-platform \
    --dry-run=client -o yaml | kubectl apply -f -
echo "  ✅ user-secret created"

# Create task secret
kubectl create secret generic task-secret \
    --from-literal=DATABASE_URL="postgresql+asyncpg://${DB_USERNAME}:${DB_PASSWORD}@${DB_ENDPOINT}:5432/task_db" \
    --namespace devops-platform \
    --dry-run=client -o yaml | kubectl apply -f -
echo "  ✅ task-secret created"

echo ""
echo "✅ All secrets created!"
echo ""
echo "Secrets created in AWS Secrets Manager:"
echo "  - devops-platform/jwt-secret"
echo "  - devops-platform/database-credentials"
echo ""
echo "Secrets created in Kubernetes:"
echo "  - auth-secret"
echo "  - user-secret"
echo "  - task-secret"

