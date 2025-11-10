# ✅ AWS Deployment Checklist

## Pre-Deployment

- [ ] AWS Account created
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] kubectl installed
- [ ] eksctl installed
- [ ] Helm 3 installed
- [ ] Docker installed and running
- [ ] Local platform tested (`bash test-all-now.sh`)

## Step-by-Step Deployment

### 1. Configure Environment
```bash
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export CLUSTER_NAME=devops-platform-eks
export DB_PASSWORD="YourSecurePassword123!"
```

- [ ] Environment variables set
- [ ] AWS credentials configured
- [ ] Region selected

### 2. Create ECR Repositories
```bash
bash aws/scripts/1-create-ecr-repos.sh
```

- [ ] ECR repositories created
- [ ] Lifecycle policies set
- [ ] Scan on push enabled

### 3. Build and Push Images
```bash
bash aws/scripts/5-build-and-push-ecr.sh
```

- [ ] All images built successfully
- [ ] Images pushed to ECR
- [ ] Images scanned for vulnerabilities

### 4. Create EKS Cluster
```bash
bash aws/scripts/2-create-eks-cluster.sh
```

⏱️ **Takes 15-20 minutes**

- [ ] EKS cluster created
- [ ] Node group created
- [ ] kubectl configured
- [ ] Nodes are ready

### 5. Install AWS Load Balancer Controller
```bash
bash aws/scripts/install-alb-controller.sh
```

- [ ] ALB controller installed
- [ ] Service account created
- [ ] Controller pods running

### 6. Create RDS Database
```bash
bash aws/scripts/3-create-rds-database.sh
```

⏱️ **Takes 10-15 minutes**

- [ ] RDS instance created
- [ ] Security groups configured
- [ ] Endpoint obtained
- [ ] Connection tested

### 7. Initialize Databases
```bash
export DB_ENDPOINT=<your-rds-endpoint>
bash aws/scripts/init-rds-databases.sh
```

- [ ] auth_db created
- [ ] user_db created
- [ ] task_db created

### 8. Create Secrets
```bash
export DB_ENDPOINT=<your-rds-endpoint>
export DB_PASSWORD="YourSecurePassword123!"
bash aws/scripts/4-create-secrets.sh
```

- [ ] AWS Secrets Manager secrets created
- [ ] Kubernetes secrets created
- [ ] Database credentials stored
- [ ] JWT secret generated

### 9. Deploy Services to EKS
```bash
bash aws/scripts/6-deploy-to-eks.sh
```

- [ ] All Helm charts deployed
- [ ] Pods are running
- [ ] Services created
- [ ] Health checks passing

### 10. Configure Ingress
```bash
# Edit ingress-aws.yaml with your domain
nano aws/kubernetes/ingress-aws.yaml

# Apply ingress
kubectl apply -f aws/kubernetes/ingress-aws.yaml
```

- [ ] Ingress configured
- [ ] ALB created
- [ ] DNS configured
- [ ] SSL/TLS working

### 11. Setup Monitoring
```bash
bash aws/scripts/7-setup-monitoring.sh
```

- [ ] Prometheus installed
- [ ] Grafana installed
- [ ] Dashboards configured
- [ ] Alerts set up

### 12. Configure DNS
```bash
# Get ALB endpoint
kubectl get ingress -n devops-platform

# Create Route 53 records
# Point your domain to ALB endpoint
```

- [ ] Route 53 hosted zone created
- [ ] DNS records created
- [ ] Domain resolves correctly

### 13. Setup SSL Certificate
```bash
# Request ACM certificate
aws acm request-certificate \
  --domain-name "*.yourdomain.com" \
  --validation-method DNS \
  --region us-east-1

# Update ingress with certificate ARN
```

- [ ] ACM certificate requested
- [ ] DNS validation completed
- [ ] Certificate ARN in ingress
- [ ] HTTPS working

## Post-Deployment Verification

### Test Health Endpoints
```bash
kubectl port-forward -n devops-platform svc/auth 8001:8000 &
curl http://localhost:8001/health
```

- [ ] Auth service responding
- [ ] User service responding
- [ ] Task service responding
- [ ] Notification service responding

### Test Database Connectivity
```bash
kubectl run -it --rm psql --image=postgres:16 --restart=Never -- \
  psql postgresql://username:password@endpoint:5432/auth_db
```

- [ ] Can connect to auth_db
- [ ] Can connect to user_db
- [ ] Can connect to task_db

### Test APIs
```bash
# Port forward and test
kubectl port-forward -n devops-platform svc/auth 8001:8000 &
curl -X POST http://localhost:8001/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123"}'
```

- [ ] Registration works
- [ ] Login works
- [ ] User CRUD works
- [ ] Task CRUD works
- [ ] Notifications work

### Monitoring Verification
```bash
# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

- [ ] Grafana accessible
- [ ] Dashboards loaded
- [ ] Metrics collecting
- [ ] Alerts configured

## Security Hardening

- [ ] Enable Pod Security Standards
- [ ] Configure Network Policies
- [ ] Enable AWS GuardDuty
- [ ] Enable AWS Config
- [ ] Setup CloudTrail
- [ ] Configure IAM roles properly
- [ ] Enable encryption everywhere
- [ ] Setup backup policies
- [ ] Configure WAF rules
- [ ] Setup DDoS protection

## CI/CD Setup

### GitHub Secrets Required
- [ ] `AWS_ACCESS_KEY_ID`
- [ ] `AWS_SECRET_ACCESS_KEY`
- [ ] `AWS_ACCOUNT_ID`
- [ ] `DOCKER_USERNAME` (if using Docker Hub too)
- [ ] `DOCKER_PASSWORD`

### Workflows
- [ ] CI/CD workflow tested
- [ ] AWS deploy workflow tested
- [ ] Auto-deployment working
- [ ] GitOps configured

## Cost Optimization

- [ ] Right-sized instances
- [ ] Auto-scaling configured
- [ ] Spot instances for dev/staging
- [ ] Reserved instances for production
- [ ] Cost alerts configured
- [ ] Budget set up

## Documentation

- [ ] Update README with AWS URLs
- [ ] Document deployment process
- [ ] Create runbooks
- [ ] Document troubleshooting
- [ ] Create disaster recovery plan

## Final Checks

- [ ] All services healthy
- [ ] Database backups working
- [ ] Monitoring active
- [ ] Logging working
- [ ] Alerts configured
- [ ] DNS resolving
- [ ] SSL/TLS working
- [ ] Auto-scaling tested
- [ ] Load balancing working
- [ ] Disaster recovery tested

## Production Readiness Score

Count your checkmarks: _____ / 80

- **80/80**: 🌟 Production ready!
- **60-79**: ⚡ Almost there
- **40-59**: 🔧 Needs work
- **<40**: ⚠️ Not ready yet

---

## 🆘 If Something Fails

1. Check logs: `kubectl logs -n devops-platform <pod-name>`
2. Check events: `kubectl get events -n devops-platform`
3. Check AWS console: CloudWatch, EKS, RDS
4. Review: `AWS_DEPLOYMENT.md`
5. Ask for help with specific error messages

---

**Good luck with your AWS deployment!** 🚀

