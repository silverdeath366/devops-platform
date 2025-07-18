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
cp .env.example .env    # or create your own
docker-compose up --build
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

## CI/CD (GitHub Actions)

Each push to `main` or `silverdeath366` triggers:

1. Docker image build
2. Push to Docker Hub:
   - `silverdeath366/auth`
   - `silverdeath366/user`
   - `silverdeath366/task`
   - `silverdeath366/notification`
3. Argo CD auto-sync from Git

> You can find workflows in `.github/workflows/`

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
├── makefile               # Useful dev commands
└── .env
```

---
