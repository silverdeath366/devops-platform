#!/bin/bash
# Cleanup AWS resources

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  AWS Resource Cleanup${NC}"
echo ""
echo "This will delete:"
echo "  - EKS Cluster"
echo "  - RDS Database"
echo "  - ECR Repositories"
echo "  - All associated resources"
echo ""
echo -e "${RED}WARNING: This is irreversible!${NC}"
echo ""

read -p "Are you sure? Type 'DELETE' to confirm: " CONFIRM
if [ "$CONFIRM" != "DELETE" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME="devops-platform-cluster"

echo ""
echo "Deleting Helm releases..."
helm uninstall auth user task notification -n devops-platform 2>/dev/null || true

echo ""
echo "Deleting RDS instance..."
aws rds delete-db-instance \
    --db-instance-identifier devops-postgres \
    --skip-final-snapshot \
    --region ${AWS_REGION} 2>/dev/null || true

echo ""
echo "Deleting EKS cluster..."
eksctl delete cluster --name ${CLUSTER_NAME} --region ${AWS_REGION}

echo ""
echo "Deleting ECR repositories..."
for service in auth user task notification; do
    aws ecr delete-repository \
        --repository-name devops-platform/${service} \
        --force \
        --region ${AWS_REGION} 2>/dev/null || true
done

echo ""
echo "✅ Cleanup complete!"

