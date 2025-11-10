#!/bin/bash
# Complete AWS cleanup - deletes everything

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-devops-platform-eks}
DB_INSTANCE_ID=${DB_INSTANCE_ID:-devops-postgres}
SERVICES=("auth" "user" "task" "notification")

echo "🧹 AWS Cleanup - Deleting All Resources"
echo "======================================="
echo ""
echo "⚠️  WARNING: This will delete:"
echo "  - EKS Cluster: $CLUSTER_NAME"
echo "  - RDS Instance: $DB_INSTANCE_ID"
echo "  - ECR Repositories"
echo "  - Secrets Manager secrets"
echo "  - Load Balancers"
echo ""
read -p "Are you sure? (type 'yes' to continue): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."
echo ""

# Delete Helm releases
echo "1. Deleting Helm releases..."
helm list -n devops-platform -q | xargs -r helm uninstall -n devops-platform 2>/dev/null || true
echo "  ✅ Helm releases deleted"

# Delete EKS cluster
echo ""
echo "2. Deleting EKS cluster (this takes 10-15 minutes)..."
eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION --wait || true
echo "  ✅ EKS cluster deleted"

# Delete RDS instance
echo ""
echo "3. Deleting RDS instance..."
aws rds delete-db-instance \
    --db-instance-identifier $DB_INSTANCE_ID \
    --skip-final-snapshot \
    --region $AWS_REGION \
    2>/dev/null || echo "  RDS instance doesn't exist"
echo "  ✅ RDS deletion initiated"

# Delete ECR repositories
echo ""
echo "4. Deleting ECR repositories..."
for service in "${SERVICES[@]}"; do
    aws ecr delete-repository \
        --repository-name devops-platform/${service} \
        --force \
        --region $AWS_REGION \
        2>/dev/null || true
    echo "  ✅ Deleted devops-platform/${service}"
done

# Delete secrets
echo ""
echo "5. Deleting Secrets Manager secrets..."
aws secretsmanager delete-secret \
    --secret-id devops-platform/jwt-secret \
    --force-delete-without-recovery \
    --region $AWS_REGION \
    2>/dev/null || true
aws secretsmanager delete-secret \
    --secret-id devops-platform/database-credentials \
    --force-delete-without-recovery \
    --region $AWS_REGION \
    2>/dev/null || true
echo "  ✅ Secrets deleted"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Note: Some resources may take a few minutes to fully delete."

