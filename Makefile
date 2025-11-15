.PHONY: help docker-build docker-up docker-down docker-logs local-test \
	build-images push-images helm-secrets helm-deploy helm-clean \
	argo-install argo-apps argo-uninstall status

REGISTRY ?= silverdeath366
VERSION ?= v2
NAMESPACE ?= dev
SERVICES := auth user task notification
HELM_DIR := helm/charts
K8S_SECRETS_DIR := k8s/secrets
APPS_DIR := apps

help:
	@echo "Usage: make <target>"
	@echo
	@echo "Local:"
	@echo "  docker-build     Build docker-compose images"
	@echo "  docker-up        Start docker-compose stack (detached)"
	@echo "  docker-down      Stop docker-compose stack"
	@echo "  docker-logs      Tail logs for all services"
	@echo "  local-test       Curl all /health endpoints on localhost"
	@echo
	@echo "Images:"
	@echo "  build-images     Build service images and tag with REGISTRY/VERSION"
	@echo "  push-images      Push tagged images to REGISTRY"
	@echo
	@echo "Kubernetes:"
	@echo "  helm-secrets     Apply ConfigMaps/Secrets into NAMESPACE"
	@echo "  helm-deploy      Upgrade/install Helm releases for all services"
	@echo "  helm-clean       Uninstall all Helm releases from NAMESPACE"
	@echo "  status           Show pod status in NAMESPACE"
	@echo
	@echo "Argo CD:"
	@echo "  argo-install     Install Argo CD controllers into 'argocd' namespace"
	@echo "  argo-apps        Apply Argo CD Application manifests"
	@echo "  argo-uninstall   Remove Argo CD namespace (cleanup)"
	@echo
	@echo "Variables (override via 'make VAR=value target'):"
	@echo "  REGISTRY=$(REGISTRY)"
	@echo "  VERSION=$(VERSION)"
	@echo "  NAMESPACE=$(NAMESPACE)"

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

local-test:
	@for port in 8001 8002 8003 8004; do \
		printf "Checking localhost:%s ... " $$port; \
		curl -sf http://localhost:$$port/health >/dev/null && echo "ok" || exit 1; \
	done

build-images:
	@for svc in $(SERVICES); do \
		echo "Building $$svc -> $(REGISTRY)/$$svc:$(VERSION)"; \
		docker build -t $(REGISTRY)/$$svc:$(VERSION) services/$$svc; \
	done

push-images:
	@for svc in $(SERVICES); do \
		echo "Pushing $(REGISTRY)/$$svc:$(VERSION)"; \
		docker push $(REGISTRY)/$$svc:$(VERSION); \
	done

helm-secrets:
	kubectl apply -n $(NAMESPACE) -f $(K8S_SECRETS_DIR)

helm-deploy: helm-secrets
	@for svc in $(SERVICES); do \
		echo "Deploying $$svc to namespace $(NAMESPACE)"; \
		helm upgrade --install $$svc $(HELM_DIR)/$$svc \
			-n $(NAMESPACE) --create-namespace \
			--set image.repository=$(REGISTRY)/$$svc \
			--set image.tag=$(VERSION); \
	done

helm-clean:
	@for svc in $(SERVICES); do \
		helm uninstall $$svc -n $(NAMESPACE) || true; \
	done

status:
	kubectl get pods -n $(NAMESPACE)

argo-install:
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argo-apps:
	kubectl apply -f $(APPS_DIR)

argo-uninstall:
	kubectl delete namespace argocd --ignore-not-found

