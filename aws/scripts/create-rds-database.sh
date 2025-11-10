#!/bin/bash
# Create RDS PostgreSQL database

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
DB_INSTANCE_ID=${DB_INSTANCE_ID:-devops-postgres}
DB_INSTANCE_CLASS=${DB_INSTANCE_CLASS:-db.t3.micro}
DB_USERNAME=${DB_USERNAME:-devopsadmin}
DB_PASSWORD=${DB_PASSWORD:-ChangeMe123!}  # Change this!
ALLOCATED_STORAGE=${ALLOCATED_STORAGE:-20}
CLUSTER_NAME=${CLUSTER_NAME:-devops-platform-eks}

echo "🗄️  Creating RDS PostgreSQL Database"
echo "===================================="
echo "Instance ID: $DB_INSTANCE_ID"
echo "Instance Class: $DB_INSTANCE_CLASS"
echo "Storage: ${ALLOCATED_STORAGE}GB"
echo ""

# Get VPC and subnet info from EKS cluster
VPC_ID=$(aws eks describe-cluster \
    --name $CLUSTER_NAME \
    --region $AWS_REGION \
    --query 'cluster.resourcesVpcConfig.vpcId' \
    --output text)

SUBNET_IDS=$(aws eks describe-cluster \
    --name $CLUSTER_NAME \
    --region $AWS_REGION \
    --query 'cluster.resourcesVpcConfig.subnetIds[0:2]' \
    --output text | tr '\t' ',')

echo "VPC ID: $VPC_ID"
echo "Subnets: $SUBNET_IDS"
echo ""

# Create DB subnet group
echo "Creating DB subnet group..."
aws rds create-db-subnet-group \
    --db-subnet-group-name ${DB_INSTANCE_ID}-subnet-group \
    --db-subnet-group-description "Subnet group for $DB_INSTANCE_ID" \
    --subnet-ids $(echo $SUBNET_IDS | tr ',' ' ') \
    --region $AWS_REGION \
    2>/dev/null || echo "  Subnet group already exists"

# Create security group for RDS
echo "Creating security group..."
SG_ID=$(aws ec2 create-security-group \
    --group-name ${DB_INSTANCE_ID}-sg \
    --description "Security group for $DB_INSTANCE_ID" \
    --vpc-id $VPC_ID \
    --region $AWS_REGION \
    --query 'GroupId' \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=${DB_INSTANCE_ID}-sg" "Name=vpc-id,Values=$VPC_ID" \
        --region $AWS_REGION \
        --query 'SecurityGroups[0].GroupId' \
        --output text)

echo "Security Group ID: $SG_ID"

# Allow PostgreSQL access from EKS nodes
NODE_SG=$(aws eks describe-cluster \
    --name $CLUSTER_NAME \
    --region $AWS_REGION \
    --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 5432 \
    --source-group $NODE_SG \
    --region $AWS_REGION \
    2>/dev/null || echo "  Security group rule already exists"

echo ""
echo "Creating RDS instance (this takes ~10 minutes)..."

# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_ID \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine postgres \
    --engine-version 16.1 \
    --master-username $DB_USERNAME \
    --master-user-password "$DB_PASSWORD" \
    --allocated-storage $ALLOCATED_STORAGE \
    --storage-type gp3 \
    --storage-encrypted \
    --db-subnet-group-name ${DB_INSTANCE_ID}-subnet-group \
    --vpc-security-group-ids $SG_ID \
    --backup-retention-period 7 \
    --preferred-backup-window "03:00-04:00" \
    --preferred-maintenance-window "sun:04:00-sun:05:00" \
    --enable-performance-insights \
    --publicly-accessible false \
    --region $AWS_REGION \
    2>/dev/null || echo "  RDS instance already exists"

echo ""
echo "Waiting for RDS instance to be available..."
aws rds wait db-instance-available \
    --db-instance-identifier $DB_INSTANCE_ID \
    --region $AWS_REGION

# Get endpoint
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo ""
echo "✅ RDS database created!"
echo ""
echo "Endpoint: $DB_ENDPOINT"
echo "Port: 5432"
echo "Username: $DB_USERNAME"
echo ""
echo "Connection strings:"
echo "  AUTH_DATABASE_URL=postgresql+asyncpg://${DB_USERNAME}:${DB_PASSWORD}@${DB_ENDPOINT}:5432/auth_db"
echo "  USER_DATABASE_URL=postgresql+asyncpg://${DB_USERNAME}:${DB_PASSWORD}@${DB_ENDPOINT}:5432/user_db"
echo "  TASK_DATABASE_URL=postgresql+asyncpg://${DB_USERNAME}:${DB_PASSWORD}@${DB_ENDPOINT}:5432/task_db"
echo ""
echo "⚠️  Save these connection strings! You'll need them for secrets."
echo ""
echo "Next step: Create databases"
echo "  bash aws/scripts/init-rds-databases.sh"

