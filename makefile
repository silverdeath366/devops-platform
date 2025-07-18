# Makefile for DevOps Platform 🔨

# === Docker Compose ===
up:
	@echo "🚀 Starting Docker Compose services..."
	docker-compose up --build -d

down:
	@echo "🛑 Stopping all services..."
	docker-compose down

build:
	@echo "🔨 Rebuilding all services..."
	docker-compose build

restart:
	@echo "🔁 Restarting stack..."
	make down
	make up

logs:
	@echo "📜 Tailing logs..."
	docker-compose logs -f

ps:
	@echo "📦 Showing running containers..."
	docker-compose ps

# === Kubernetes / Argo CD ===

argo-up:
	@echo "🌐 Forwarding Argo CD UI to http://localhost:9000 ..."
	kubectl port-forward svc/argocd-server -n argocd 9000:443

port-forward:
	@echo "🔁 Port-forwarding microservices from Minikube cluster..."
        kubectl port-forward svc/auth 8001:8000 &
	kubectl port-forward svc/user 8002:8000 &
	kubectl port-forward svc/task 8003:8000 &
	kubectl port-forward svc/notification 8004:8000 &
	@echo "➡️  Access services at:"
	@echo "   http://localhost:8001 (auth)"
	@echo "   http://localhost:8002 (user)"
	@echo "   http://localhost:8003 (task)"
	@echo "   http://localhost:8004 (notification)"

k8s-clean:
	@echo "🧹 Cleaning Argo CD apps and Helm releases..."
	kubectl delete -f apps/ --ignore-not-found=true
	helm uninstall auth || true
	helm uninstall user || true
	helm uninstall task || true
	helm uninstall notification || true

# === Docker Image Build & Push ===

docker-build:
	@echo "🔨 Building Docker images..."
	docker build -t silverdeath366/auth:latest ./services/auth
	docker build -t silverdeath366/user:latest ./services/user
	docker build -t silverdeath366/task:latest ./services/task
	docker build -t silverdeath366/notification:latest ./services/notification

# Tip: Add --no-cache above if you want fresh builds every time

push:
	@echo "🚀 Pushing Docker images to Docker Hub..."
	docker push silverdeath366/auth:latest
	docker push silverdeath366/user:latest
	docker push silverdeath366/task:latest
	docker push silverdeath366/notification:latest

# === Argo CD Deployment ===

argo-deploy:
	@echo "📦 Applying Argo CD app manifests..."
	kubectl apply -f apps/

argo-sync:
	@echo "🔄 Syncing Argo CD apps..."
	argocd app sync auth || true
	argocd app sync user || true
	argocd app sync task || true
	argocd app sync notification || true

# === Master Setup ===

setup: docker-build push argo-deploy argo-sync argo-up

# === Help ===

help:
	@echo "🛠️  DevOps Makefile — Available Commands:"
	@echo "  make up             🚀 Start Docker Compose stack"
	@echo "  make down           🛑 Stop services"
	@echo "  make logs           📜 Tail container logs"
	@echo "  make restart        🔁 Restart local stack"
	@echo "  make ps             📦 Show running containers"
	@echo "  make docker-build   🔨 Build Docker images"
	@echo "  make push           🚀 Push Docker images to Docker Hub"
	@echo "  make argo-deploy    📦 Apply Argo CD apps"
	@echo "  make argo-sync      🔄 Sync Argo CD apps"
	@echo "  make argo-up        🌐 Port-forward Argo CD (http://localhost:9000)"
	@echo "  make port-forward   🔁 Port-forward all services (8001–8004)"
	@echo "  make k8s-clean      🧹 Clean all Argo CD apps + Helm"
	@echo "  make setup          ⚙️  Build, deploy, sync, and port-forward Argo CD"
