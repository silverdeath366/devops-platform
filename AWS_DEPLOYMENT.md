# 🚀 AWS Deployment Guide

Complete guide for deploying the DevOps Platform to AWS using EKS, RDS, ECR, and other AWS services.

---

## 📋 Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- kubectl installed
- eksctl installed
- Helm 3 installed
- Docker installed

---

## 🏗️ Architecture on AWS

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Cloud                              │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │            Amazon EKS Cluster                         │ │
│  │                                                       │ │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐         │ │
│  │   │   Auth   │  │   User   │  │   Task   │         │ │
│  │   │  Service │  │  Service │  │  Service │         │ │
│  │   └─────┬────┘  └─────┬────┘  └─────┬────┘         │ │
│  │         │             │             │               │ │
│  │         └─────────────┼─────────────┘               │ │
│  │                       │                             │ │
│  │   ┌───────────────────▼───────────────────┐         │ │
│  │   │    Application Load Balancer          │         │ │
│  │   └───────────────────────────────────────┘         │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │         Amazon RDS PostgreSQL                         │ │
│  │    (auth_db, user_db, task_db)                       │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │         Amazon ECR (Container Registry)               │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │      AWS Secrets Manager (Credentials)                │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Deployment Steps

### 1. Set Environment Variables

```bash
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export CLUSTER_NAME=devops-platform-eks
export ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

### 2. Create ECR Repositories

```bash
bash aws/scripts/create-ecr-repos.sh
```

### 3. Create EKS Cluster

```bash
bash aws/scripts/create-eks-cluster.sh
```

### 4. Create RDS Database

```bash
bash aws/scripts/create-rds-database.sh
```

### 5. Setup AWS Secrets

```bash
bash aws/scripts/create-secrets.sh
```

### 6. Build and Push Images to ECR

```bash
bash aws/scripts/build-and-push-ecr.sh
```

### 7. Deploy to EKS

```bash
bash aws/scripts/deploy-to-eks.sh
```

### 8. Setup Monitoring

```bash
bash aws/scripts/setup-monitoring.sh
```

---

## 📊 AWS Services Used

| Service | Purpose | Estimated Cost |
|---------|---------|----------------|
| **Amazon EKS** | Kubernetes cluster | ~$75/month |
| **Amazon RDS** | PostgreSQL database | ~$30/month |
| **Amazon ECR** | Container registry | ~$5/month |
| **AWS Secrets Manager** | Secret management | ~$2/month |
| **Application Load Balancer** | Traffic distribution | ~$20/month |
| **Amazon CloudWatch** | Logging & monitoring | ~$10/month |
| **Total** | | **~$142/month** |

---

## 🔒 Security Best Practices

1. ✅ **Use AWS Secrets Manager** for sensitive data
2. ✅ **Enable encryption** at rest and in transit
3. ✅ **Use IAM roles** instead of access keys where possible
4. ✅ **Enable VPC** for network isolation
5. ✅ **Use security groups** to restrict traffic
6. ✅ **Enable AWS GuardDuty** for threat detection
7. ✅ **Enable AWS CloudTrail** for audit logging
8. ✅ **Use AWS WAF** for application firewall

---

## 📈 Monitoring & Logging

### CloudWatch Setup
```bash
# Install CloudWatch agent
kubectl apply -f aws/kubernetes/cloudwatch-agent.yaml

# View logs
aws logs tail /aws/eks/devops-platform --follow
```

### Prometheus + Grafana
```bash
# Install monitoring stack
bash aws/scripts/setup-monitoring.sh

# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
```

---

## 🔄 CI/CD with GitHub Actions

The platform includes GitHub Actions workflows for:

1. **Build** → Build Docker images
2. **Test** → Run all tests
3. **Scan** → Security scanning (Trivy, Snyk)
4. **Push** → Push to ECR
5. **Deploy** → Deploy to EKS via GitOps

See `.github/workflows/aws-deploy.yaml`

---

## 🎯 Auto-Scaling

### Horizontal Pod Autoscaling (HPA)
- Automatically scales pods based on CPU/memory
- Min replicas: 2
- Max replicas: 10

### Cluster Autoscaling
```bash
# Install cluster autoscaler
kubectl apply -f aws/kubernetes/cluster-autoscaler.yaml
```

---

## 💾 Database Management

### RDS PostgreSQL

**Connection string format:**
```
postgresql+asyncpg://username:password@endpoint:5432/database
```

**Backup & Recovery:**
- Automated daily backups
- Point-in-time recovery
- 7-day retention period

**Monitoring:**
- Enhanced monitoring enabled
- Performance insights enabled
- CloudWatch alarms for CPU/storage

---

## 🌐 DNS & SSL

### Setup Domain
1. Create Route 53 hosted zone
2. Point domain to ALB
3. Request ACM certificate
4. Configure Ingress with TLS

```bash
# Update Ingress with your domain
kubectl apply -f aws/kubernetes/ingress-ssl.yaml
```

---

## 🧹 Cleanup

### Delete Everything
```bash
bash aws/scripts/cleanup-all.sh
```

This will:
- Delete EKS cluster
- Delete RDS database
- Delete ECR repositories
- Delete Secrets
- Delete CloudWatch logs

---

## 📚 Additional Resources

- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)

---

## 🆘 Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Database connection issues
```bash
# Test connection from within cluster
kubectl run -it --rm debug --image=postgres:16 --restart=Never -- \
  psql postgresql://username:password@endpoint:5432/database
```

### ECR authentication issues
```bash
# Re-authenticate
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REGISTRY
```

---

**Ready to deploy to AWS? Run: `bash test-all-now.sh` first to verify everything works locally!** 🚀

