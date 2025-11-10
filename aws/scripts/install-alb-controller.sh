#!/bin/bash
# Install AWS Load Balancer Controller

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-devops-platform-eks}

echo "🔧 Installing AWS Load Balancer Controller"
echo "=========================================="
echo ""

# Add Helm repo
echo "Adding eks-charts Helm repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Create IAM service account
echo ""
echo "Creating IAM service account for ALB controller..."
eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
    --region=$AWS_REGION \
    --approve \
    --override-existing-serviceaccounts

# Install ALB controller
echo ""
echo "Installing AWS Load Balancer Controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set region=$AWS_REGION \
    --wait

echo ""
echo "✅ AWS Load Balancer Controller installed!"
echo ""
echo "Verifying installation..."
kubectl get deployment -n kube-system aws-load-balancer-controller
echo ""
echo "You can now use ALB Ingress in your services!"

