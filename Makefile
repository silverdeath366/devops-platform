# ============================================
# DevOps Microservices Platform - Makefile
# ============================================
# Production-grade automation for development, testing, and deployment

.PHONY: help
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Configuration
SERVICES := auth user task notification
DOCKER_REGISTRY ?= silverdeath366
DOCKER_TAG ?= latest
K8S_NAMESPACE ?= default

# AWS Configuration
AWS_REGION ?= us-east-1
AWS_ACCOUNT_ID ?= $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "NOT_SET")
ECR_REGISTRY ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

# ============================================
# Help
# ============================================
help: ## Show this help message
	@echo "$(BLUE)DevOps Microservices Platform$(NC)"
	@echo "$(GREEN)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ============================================
# Development Setup
# ============================================
.PHONY: setup
setup: ## Initial project setup
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@cp -n .env.example .env 2>/dev/null || true
	@echo "$(GREEN)✓ Environment file created$(NC)"
	@$(MAKE) install-dev
	@echo "$(GREEN)✓ Setup complete!$(NC)"

.PHONY: install-dev
install-dev: ## Install development dependencies
	@echo "$(BLUE)Installing development dependencies...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Installing dependencies for $$service...$(NC)"; \
		pip install -r services/$$service/requirements.txt || true; \
	done
	@pip install pytest pytest-asyncio pytest-cov ruff mypy black
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

# ============================================
# Code Quality
# ============================================
.PHONY: lint
lint: ## Run linters (ruff, black, mypy)
	@echo "$(BLUE)Running linters...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Linting $$service...$(NC)"; \
		cd services/$$service && \
		ruff check app/ tests/ || true && \
		black --check app/ tests/ || true && \
		mypy app/ --ignore-missing-imports || true && \
		cd ../..; \
	done
	@echo "$(GREEN)✓ Linting complete$(NC)"

.PHONY: format
format: ## Format code with black
	@echo "$(BLUE)Formatting code...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Formatting $$service...$(NC)"; \
		cd services/$$service && black app/ tests/ && cd ../..; \
	done
	@echo "$(GREEN)✓ Code formatted$(NC)"

# ============================================
# Testing
# ============================================
.PHONY: test
test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Testing $$service...$(NC)"; \
		cd services/$$service && \
		pytest tests/ -v --cov=app --cov-report=term && \
		cd ../..; \
	done
	@echo "$(GREEN)✓ All tests passed$(NC)"

.PHONY: test-service
test-service: ## Run tests for specific service (make test-service SERVICE=auth)
	@echo "$(BLUE)Testing $(SERVICE)...$(NC)"
	@cd services/$(SERVICE) && pytest tests/ -v --cov=app --cov-report=term
	@echo "$(GREEN)✓ Tests passed$(NC)"

# ============================================
# Docker Operations
# ============================================
.PHONY: build
build: ## Build all Docker images
	@echo "$(BLUE)Building Docker images...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Building $$service...$(NC)"; \
		docker build -t $(DOCKER_REGISTRY)/$$service:$(DOCKER_TAG) services/$$service; \
	done
	@echo "$(GREEN)✓ All images built$(NC)"

.PHONY: build-service
build-service: ## Build specific service (make build-service SERVICE=auth)
	@echo "$(BLUE)Building $(SERVICE)...$(NC)"
	@docker build -t $(DOCKER_REGISTRY)/$(SERVICE):$(DOCKER_TAG) services/$(SERVICE)
	@echo "$(GREEN)✓ Image built$(NC)"

.PHONY: push
push: ## Push all Docker images to registry
	@echo "$(BLUE)Pushing Docker images...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Pushing $$service...$(NC)"; \
		docker push $(DOCKER_REGISTRY)/$$service:$(DOCKER_TAG); \
	done
	@echo "$(GREEN)✓ All images pushed$(NC)"

.PHONY: docker-up
docker-up: ## Start services with Docker Compose (dev profile)
	@echo "$(BLUE)Starting services with Docker Compose...$(NC)"
	@docker-compose --profile dev up -d
	@echo "$(GREEN)✓ Services started$(NC)"
	@echo "$(YELLOW)Access services at:$(NC)"
	@echo "  Auth:         http://localhost:8001/health"
	@echo "  User:         http://localhost:8002/health"
	@echo "  Task:         http://localhost:8003/health"
	@echo "  Notification: http://localhost:8004/health"

.PHONY: docker-up-postgres
docker-up-postgres: ## Start services with Docker Compose (with PostgreSQL)
	@echo "$(BLUE)Starting services with PostgreSQL...$(NC)"
	@docker-compose --profile dev --profile postgres up -d
	@echo "$(GREEN)✓ Services started with PostgreSQL$(NC)"

.PHONY: docker-down
docker-down: ## Stop Docker Compose services
	@echo "$(BLUE)Stopping services...$(NC)"
	@docker-compose --profile dev --profile postgres down
	@echo "$(GREEN)✓ Services stopped$(NC)"

.PHONY: docker-logs
docker-logs: ## Show logs from Docker Compose
	@docker-compose --profile dev logs -f

# ============================================
# Kubernetes / Helm Operations
# ============================================
.PHONY: k8s-deploy
k8s-deploy: ## Deploy all services to Kubernetes using Helm
	@echo "$(BLUE)Deploying to Kubernetes...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Deploying $$service...$(NC)"; \
		helm upgrade --install $$service helm/charts/$$service \
			--namespace $(K8S_NAMESPACE) \
			--create-namespace; \
	done
	@echo "$(GREEN)✓ All services deployed$(NC)"

.PHONY: k8s-undeploy
k8s-undeploy: ## Remove all services from Kubernetes
	@echo "$(BLUE)Removing services from Kubernetes...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Removing $$service...$(NC)"; \
		helm uninstall $$service --namespace $(K8S_NAMESPACE) || true; \
	done
	@echo "$(GREEN)✓ All services removed$(NC)"

.PHONY: k8s-status
k8s-status: ## Check Kubernetes deployment status
	@echo "$(BLUE)Kubernetes Status:$(NC)"
	@kubectl get pods -n $(K8S_NAMESPACE)
	@kubectl get svc -n $(K8S_NAMESPACE)

.PHONY: k8s-logs
k8s-logs: ## Show logs from Kubernetes pods (make k8s-logs SERVICE=auth)
	@kubectl logs -n $(K8S_NAMESPACE) -l app=$(SERVICE) --tail=100 -f

# ============================================
# Minikube Operations
# ============================================
.PHONY: minikube-start
minikube-start: ## Start Minikube cluster
	@echo "$(BLUE)Starting Minikube...$(NC)"
	@minikube start --cpus=4 --memory=8192
	@minikube addons enable ingress
	@minikube addons enable metrics-server
	@echo "$(GREEN)✓ Minikube started$(NC)"

.PHONY: minikube-stop
minikube-stop: ## Stop Minikube cluster
	@echo "$(BLUE)Stopping Minikube...$(NC)"
	@minikube stop
	@echo "$(GREEN)✓ Minikube stopped$(NC)"

.PHONY: minikube-deploy
minikube-deploy: ## Deploy to Minikube
	@$(MAKE) build
	@eval $$(minikube docker-env) && $(MAKE) k8s-deploy
	@echo "$(GREEN)✓ Deployed to Minikube$(NC)"

# ============================================
# Argo CD Operations
# ============================================
.PHONY: argocd-install
argocd-install: ## Install Argo CD
	@echo "$(BLUE)Installing Argo CD...$(NC)"
	@kubectl create namespace argocd || true
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "$(GREEN)✓ Argo CD installed$(NC)"
	@echo "$(YELLOW)Get admin password with: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d$(NC)"

.PHONY: argocd-ui
argocd-ui: ## Open Argo CD UI
	@echo "$(BLUE)Opening Argo CD UI...$(NC)"
	@kubectl port-forward svc/argocd-server -n argocd 9000:443

.PHONY: argocd-sync
argocd-sync: ## Sync all Argo CD applications
	@echo "$(BLUE)Syncing Argo CD applications...$(NC)"
	@for service in $(SERVICES); do \
		argocd app sync $$service || true; \
	done
	@echo "$(GREEN)✓ Applications synced$(NC)"

# ============================================
# Cleanup
# ============================================
.PHONY: clean
clean: ## Clean up generated files and caches
	@echo "$(BLUE)Cleaning up...$(NC)"
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@find . -type f -name "*.db" -delete 2>/dev/null || true
	@find . -type f -name "*.db-journal" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

.PHONY: clean-docker
clean-docker: ## Remove all Docker containers and images
	@echo "$(BLUE)Cleaning Docker resources...$(NC)"
	@docker-compose down -v 2>/dev/null || true
	@for service in $(SERVICES); do \
		docker rmi $(DOCKER_REGISTRY)/$$service:$(DOCKER_TAG) 2>/dev/null || true; \
	done
	@echo "$(GREEN)✓ Docker cleanup complete$(NC)"

# ============================================
# AWS Operations
# ============================================
.PHONY: aws-login
aws-login: ## Login to AWS ECR
	@echo "$(BLUE)Logging into AWS ECR...$(NC)"
	@aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $(ECR_REGISTRY)
	@echo "$(GREEN)✓ Logged into ECR$(NC)"

.PHONY: aws-create-repos
aws-create-repos: ## Create ECR repositories
	@echo "$(BLUE)Creating ECR repositories...$(NC)"
	@for service in $(SERVICES); do \
		echo "Creating repo for $$service..."; \
		aws ecr create-repository \
			--repository-name devops-platform/$$service \
			--region $(AWS_REGION) 2>/dev/null || echo "  Repository exists"; \
	done
	@echo "$(GREEN)✓ ECR repositories ready$(NC)"

.PHONY: aws-build-push
aws-build-push: aws-login ## Build and push images to ECR
	@echo "$(BLUE)Building and pushing to ECR...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Building $$service for ECR...$(NC)"; \
		docker build -t $(ECR_REGISTRY)/devops-platform/$$service:$(DOCKER_TAG) services/$$service; \
		docker push $(ECR_REGISTRY)/devops-platform/$$service:$(DOCKER_TAG); \
	done
	@echo "$(GREEN)✓ All images pushed to ECR$(NC)"

.PHONY: aws-deploy-full
aws-deploy-full: ## Full AWS deployment (EKS + RDS + Services)
	@echo "$(BLUE)Starting AWS deployment...$(NC)"
	@bash aws/deploy-to-aws.sh

.PHONY: aws-cleanup
aws-cleanup: ## Cleanup AWS resources (WARNING: Deletes everything!)
	@echo "$(RED)⚠️  This will delete all AWS resources!$(NC)"
	@bash aws/cleanup-aws.sh

.PHONY: aws-update-helm
aws-update-helm: ## Update Helm values for ECR
	@echo "$(BLUE)Updating Helm values for ECR...$(NC)"
	@for service in $(SERVICES); do \
		sed -i.bak "s|repository:.*|repository: $(ECR_REGISTRY)/devops-platform/$$service|" \
			helm/charts/$$service/values.yaml; \
	done
	@echo "$(GREEN)✓ Helm values updated for ECR$(NC)"

# ============================================
# Quick Start
# ============================================
.PHONY: quickstart
quickstart: setup docker-up ## Quick start (setup + run with Docker Compose)
	@echo "$(GREEN)✓ Quick start complete!$(NC)"
	@echo "$(YELLOW)Services are running. Check health endpoints:$(NC)"
	@sleep 5
	@curl -s http://localhost:8001/health | jq . || echo "Auth: Not ready yet"
	@curl -s http://localhost:8002/health | jq . || echo "User: Not ready yet"
	@curl -s http://localhost:8003/health | jq . || echo "Task: Not ready yet"
	@curl -s http://localhost:8004/health | jq . || echo "Notification: Not ready yet"

