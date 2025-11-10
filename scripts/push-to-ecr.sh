#!/bin/bash
# Push all images to AWS ECR

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Pushing images to AWS ECR${NC}"
echo ""

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_TAG=${IMAGE_TAG:-latest}

echo "Configuration:"
echo "  AWS Region: $AWS_REGION"
echo "  AWS Account: $AWS_ACCOUNT_ID"
echo "  ECR Registry: $ECR_REGISTRY"
echo "  Image Tag: $IMAGE_TAG"
echo ""

# Login to ECR
echo -e "${YELLOW}Logging into ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ECR_REGISTRY}
echo -e "${GREEN}✓ Logged in${NC}"
echo ""

# Create repositories if they don't exist
echo -e "${YELLOW}Ensuring ECR repositories exist...${NC}"
for service in auth user task notification; do
    aws ecr create-repository \
        --repository-name devops-platform/${service} \
        --region ${AWS_REGION} 2>/dev/null || echo "  Repository devops-platform/${service} exists"
done
echo -e "${GREEN}✓ Repositories ready${NC}"
echo ""

# Build and push each service
for service in auth user task notification; do
    echo -e "${YELLOW}Processing $service...${NC}"
    
    # Build
    echo "  Building..."
    docker build -t ${ECR_REGISTRY}/devops-platform/${service}:${IMAGE_TAG} services/${service}
    
    # Tag as latest if not already
    if [ "$IMAGE_TAG" != "latest" ]; then
        docker tag ${ECR_REGISTRY}/devops-platform/${service}:${IMAGE_TAG} \
                   ${ECR_REGISTRY}/devops-platform/${service}:latest
    fi
    
    # Push
    echo "  Pushing..."
    docker push ${ECR_REGISTRY}/devops-platform/${service}:${IMAGE_TAG}
    
    if [ "$IMAGE_TAG" != "latest" ]; then
        docker push ${ECR_REGISTRY}/devops-platform/${service}:latest
    fi
    
    echo -e "${GREEN}  ✓ $service pushed${NC}"
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    All images pushed to ECR! 🚀            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo "Images pushed:"
for service in auth user task notification; do
    echo "  ${ECR_REGISTRY}/devops-platform/${service}:${IMAGE_TAG}"
done
echo ""
echo "To deploy to EKS:"
echo "  make aws-update-helm"
echo "  make k8s-deploy"

