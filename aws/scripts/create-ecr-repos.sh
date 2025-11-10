#!/bin/bash
# Create ECR repositories for all services

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
SERVICES=("auth" "user" "task" "notification")

echo "🏗️  Creating ECR Repositories"
echo "Region: $AWS_REGION"
echo "Account: $AWS_ACCOUNT_ID"
echo ""

for service in "${SERVICES[@]}"; do
    echo "Creating repository for $service..."
    
    aws ecr create-repository \
        --repository-name devops-platform/${service} \
        --region $AWS_REGION \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256 \
        2>/dev/null || echo "  Repository already exists"
    
    # Set lifecycle policy to clean up old images
    aws ecr put-lifecycle-policy \
        --repository-name devops-platform/${service} \
        --region $AWS_REGION \
        --lifecycle-policy-text '{
            "rules": [{
                "rulePriority": 1,
                "description": "Keep last 10 images",
                "selection": {
                    "tagStatus": "any",
                    "countType": "imageCountMoreThan",
                    "countNumber": 10
                },
                "action": {
                    "type": "expire"
                }
            }]
        }' > /dev/null 2>&1
    
    echo "  ✅ Repository created: devops-platform/${service}"
done

echo ""
echo "✅ All ECR repositories created!"
echo ""
echo "To authenticate Docker to ECR, run:"
echo "  aws ecr get-login-password --region $AWS_REGION | \\"
echo "    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

