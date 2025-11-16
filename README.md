#  DevOps Microservices Platform

A fully containerized, GitOps-enabled microservices platform designed to showcase modern DevOps practices for interviews and production-ready prototypes.

---

##  Architecture Overview

This project contains **4 microservices**:

- `auth` – Authentication logic
- `user` – User profile service
- `task` – Task management API
- `notification` – Sends out alerts/notifications

Each service is:

- Built with Python (FastAPI)
- Exposes a `/health` endpoint
- Packaged with its own `Dockerfile`
- Deployable via Helm charts
- Synced with Argo CD from GitHub

---

##  Docker Setup (Local Testing)

### Requirements:
- Docker
- `docker-compose`

### Quickstart:

```bash
cp .env.example .env    # or create your own with ports:
# AUTH_PORT=8001; USER_PORT=8002; TASK_PORT=8003; NOTIFICATION_PORT=8004
docker compose up --build -d
```

Access the services:

| Service       | URL                   |
|---------------|------------------------|
| Auth          | http://localhost:8001/health |
| User          | http://localhost:8002/health |
| Task          | http://localhost:8003/health |
| Notification  | http://localhost:8004/health |

---

## 🎛️Kubernetes Deployment

### Tooling Used:

- **Minikube** for local K8s cluster
- **Helm** for packaging and deploying
- **Argo CD** for GitOps continuous deployment
- **GitHub Actions** for CI/CD (build → push → deploy)

---

## ⚙️GitOps with Argo CD

Argo CD automatically syncs apps from GitHub:

- All services live in `helm/charts/<service-name>`
- Argo CD applications defined in `apps/`
- Syncs from branch: `silverdeath366`

To access Argo CD UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 9000:443
```

Then open: `https://localhost:9000`

> First-time login default user: `admin`, password: run  
> `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

---

## 🛠️ Quick Start (Fresh Clone)

1) Local smoke test
```bash
docker compose build && docker compose up -d
curl http://localhost:8001/health && curl http://localhost:8002/health && \
curl http://localhost:8003/health && curl http://localhost:8004/health
```

2) Build and push images
```bash
docker build -t silverdeath366/auth:v2 services/auth
docker build -t silverdeath366/user:v2 services/user
docker build -t silverdeath366/task:v2 services/task
docker build -t silverdeath366/notification:v2 services/notification
docker push silverdeath366/auth:v2 && docker push silverdeath366/user:v2 && \
docker push silverdeath366/task:v2 && docker push silverdeath366/notification:v2
```

3) Kubernetes deploy (namespace `dev`)
```bash
kubectl create ns dev --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n dev -f k8s/secrets/
helm upgrade --install auth helm/charts/auth -n dev --set image.tag=v2
helm upgrade --install user helm/charts/user -n dev --set image.tag=v2
helm upgrade --install task helm/charts/task -n dev --set image.tag=v2
helm upgrade --install notification helm/charts/notification -n dev --set image.tag=v2
kubectl get pods -n dev
```

4) Argo CD
```bash
kubectl create ns argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f apps/   # applications now target namespace 'dev'
kubectl port-forward svc/argocd-server -n argocd 9000:443
# UI: https://localhost:9000  (admin / password below)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

5) Self-heal demo
```bash
kubectl delete deployment auth -n dev
kubectl get pods -n dev -w
```

## CI/CD (GitHub Actions)

Each push to `main` triggers:

1. Docker image build
2. Push to Docker Hub:
   - `silverdeath366/auth`
   - `silverdeath366/user`
   - `silverdeath366/task`
   - `silverdeath366/notification`
3. Argo CD auto-sync from Git

> You can find workflows in `.github/workflows/`

### CI/CD details
- Four workflows (`auth`/`user`/`task`/`notification`) live under `.github/workflows/`.
- Each job:
  1. Runs the service unit tests (`pytest services/<svc>/tests`).
  2. Builds a Docker image tagged with the short SHA.
  3. Pushes to Docker Hub (`silverdeath366/<svc>`).
  4. Updates the Helm values to reference the new SHA tag (keeps Git + Argo in sync).
- Workflows trigger automatically on every push to `main`, or manually via **Run workflow** (ensure repo settings → Actions → “Allow GitHub Actions to run this repository” is enabled).
- Required GitHub secrets:
  - `DOCKER_USERNAME`
  - `DOCKER_PASSWORD`

To trigger manually, push to `main` (or use **Run workflow** in GitHub UI) with changes under `services/<svc>/**`. Successful runs automatically feed Argo CD, which reconciles the cluster using the updated charts.

---

## Project Structure

```bash
.
├── services/
│   ├── auth/
│   ├── user/
│   ├── task/
│   └── notification/
├── helm/
│   └── charts/
├── apps/                  # Argo CD app manifests
├── k8s/                   # Secrets, ConfigMaps
├── docker-compose.yaml
└── .env.example
```

---
