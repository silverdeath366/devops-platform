#!/bin/bash
# Create EKS cluster with eksctl

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-devops-platform-eks}
NODE_TYPE=${NODE_TYPE:-t3.medium}
MIN_NODES=${MIN_NODES:-2}
MAX_NODES=${MAX_NODES:-5}
DESIRED_NODES=${DESIRED_NODES:-3}

echo "🏗️  Creating EKS Cluster"
echo "========================"
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo "Node Type: $NODE_TYPE"
echo "Nodes: $MIN_NODES - $MAX_NODES (desired: $DESIRED_NODES)"
echo ""
echo "⚠️  This will take 15-20 minutes..."
echo ""

# Create EKS cluster
eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $AWS_REGION \
    --nodegroup-name standard-workers \
    --node-type $NODE_TYPE \
    --nodes $DESIRED_NODES \
    --nodes-min $MIN_NODES \
    --nodes-max $MAX_NODES \
    --managed \
    --with-oidc \
    --ssh-access=false \
    --full-ecr-access \
    --alb-ingress-access \
    --asg-access \
    --enable-ssm

echo ""
echo "✅ EKS cluster created!"
echo ""

# Update kubeconfig
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

echo ""
echo "Verifying cluster..."
kubectl get nodes

echo ""
echo "✅ Cluster ready!"
echo ""
echo "Next steps:"
echo "  1. Install AWS Load Balancer Controller: bash aws/scripts/install-alb-controller.sh"
echo "  2. Install metrics server: kubectl apply -f aws/kubernetes/metrics-server.yaml"
echo "  3. Create RDS database: bash aws/scripts/create-rds-database.sh"

