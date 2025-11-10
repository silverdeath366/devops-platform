#!/bin/bash
# Build and push Docker images to ECR

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
DOCKER_TAG=${DOCKER_TAG:-latest}
SERVICES=("auth" "user" "task" "notification")

echo "🐳 Building and Pushing to ECR"
echo "=============================="
echo "Registry: $ECR_REGISTRY"
echo "Tag: $DOCKER_TAG"
echo ""

# Authenticate Docker to ECR
echo "Authenticating to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ECR_REGISTRY

echo "✅ Authenticated to ECR"
echo ""

# Build and push each service
for service in "${SERVICES[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Processing: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    IMAGE_NAME="${ECR_REGISTRY}/devops-platform/${service}"
    
    echo "Building $service..."
    docker build -t ${IMAGE_NAME}:${DOCKER_TAG} \
                 -t ${IMAGE_NAME}:$(git rev-parse --short HEAD 2>/dev/null || echo "local") \
                 services/${service}
    
    echo "Pushing $service..."
    docker push ${IMAGE_NAME}:${DOCKER_TAG}
    docker push ${IMAGE_NAME}:$(git rev-parse --short HEAD 2>/dev/null || echo "local") || true
    
    echo "✅ $service pushed to ECR"
    echo ""
done

echo "✅ All images built and pushed to ECR!"
echo ""
echo "Images:"
for service in "${SERVICES[@]}"; do
    echo "  ${ECR_REGISTRY}/devops-platform/${service}:${DOCKER_TAG}"
done
echo ""
echo "Next step: Deploy to EKS"
echo "  bash aws/scripts/deploy-to-eks.sh"

