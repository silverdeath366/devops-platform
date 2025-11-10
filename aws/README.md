# 🚀 AWS Deployment Guide

Complete guide for deploying the DevOps Platform to AWS.

## Architecture

```
AWS Cloud
├── EKS Cluster (Kubernetes)
├── RDS PostgreSQL (Database)
├── ECR (Container Registry)
├── ALB (Application Load Balancer)
├── Route53 (DNS)
├── ACM (SSL Certificates)
└── Secrets Manager (Secrets)
```

## Prerequisites

- AWS CLI configured
- kubectl installed
- eksctl installed
- Helm 3 installed
- Docker installed

## Quick Deploy

```bash
# 1. Set your AWS region and account
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 2. Run deployment
bash aws/deploy-to-aws.sh
```

## Manual Step-by-Step

See [DEPLOYMENT.md](../DEPLOYMENT.md) for detailed manual steps.

## Cost Estimate

- EKS Cluster: ~$73/month
- RDS db.t3.micro: ~$15/month
- ALB: ~$20/month
- **Total: ~$108/month**

## Cleanup

```bash
bash aws/cleanup-aws.sh
```
