#!/bin/bash
# Deploy all services to EKS

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
CLUSTER_NAME=${CLUSTER_NAME:-devops-platform-eks}
NAMESPACE=${NAMESPACE:-devops-platform}
DOCKER_TAG=${DOCKER_TAG:-latest}
SERVICES=("auth" "user" "task" "notification")

echo "🚀 Deploying to EKS"
echo "=================="
echo "Cluster: $CLUSTER_NAME"
echo "Namespace: $NAMESPACE"
echo "Registry: $ECR_REGISTRY"
echo ""

# Update kubeconfig
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Create namespace
kubectl create namespace $NAMESPACE 2>/dev/null || true

echo "Deploying services..."
echo ""

for service in "${SERVICES[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Deploying: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Update image repository in values file temporarily
    IMAGE_REPO="${ECR_REGISTRY}/devops-platform/${service}"
    
    # Deploy with Helm
    helm upgrade --install $service helm/charts/$service \
        --namespace $NAMESPACE \
        --set image.repository=$IMAGE_REPO \
        --set image.tag=$DOCKER_TAG \
        --set environment=production \
        --wait \
        --timeout 5m
    
    echo "✅ $service deployed"
    echo ""
done

echo ""
echo "✅ All services deployed to EKS!"
echo ""
echo "Checking status..."
kubectl get pods -n $NAMESPACE
echo ""
kubectl get svc -n $NAMESPACE
echo ""
echo "Next steps:"
echo "  1. Configure ingress: kubectl apply -f aws/kubernetes/ingress-aws.yaml"
echo "  2. Check logs: kubectl logs -n $NAMESPACE -l app=auth"
echo "  3. Set up monitoring: bash aws/scripts/setup-monitoring.sh"

