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

## 🛠️ End-to-End Workflow (Fresh Clone)

The `Makefile` captures every command we ran while bringing the platform up from scratch. After cloning:

1. **Local smoke test**
   ```bash
   make docker-build
   make docker-up
   make local-test   # curls all /health endpoints
   ```
   Tear down with `make docker-down` when done.

2. **Build + push release images (override versions as needed)**
   ```bash
   make build-images REGISTRY=silverdeath366 VERSION=v2
   make push-images  REGISTRY=silverdeath366 VERSION=v2
   ```

3. **Deploy to Kubernetes**
   ```bash
   make helm-deploy NAMESPACE=dev REGISTRY=silverdeath366 VERSION=v2
   make status NAMESPACE=dev
   ```

4. **Install Argo CD + register apps (once per cluster)**
   ```bash
   make argo-install
   make argo-apps
   ```

5. **Access Argo UI / CLI**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 9000:443   # UI
   kubectl port-forward svc/argocd-server -n argocd 9999:443   # CLI
   argocd login localhost:9999 --username admin \
     --password $(kubectl -n argocd get secret argocd-initial-admin-secret \
       -o jsonpath="{.data.password}" | base64 -d) --insecure
   ```

6. **Self-heal demo**
   ```bash
   kubectl delete deployment auth -n dev
   # Argo marks app OutOfSync, then recreates the deployment automatically.
   kubectl get pods -n dev
   ```

All secrets/ConfigMaps used by Helm live in `k8s/secrets/`; the `helm-deploy` target applies them before each release install. When bumping image versions, update `VERSION` (Makefile) and commit the Helm `values.yaml` change so Argo deploys the same tag.

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

### CI/CD details
- Four workflows (`auth`/`user`/`task`/`notification`) live under `.github/workflows/`.
- Each job:
  1. Runs the service unit tests (`pytest services/<svc>/tests`).
  2. Builds a Docker image tagged with the short SHA.
  3. Pushes to Docker Hub (`silverdeath366/<svc>`).
  4. Updates the Helm values to reference the new SHA tag (keeps Git + Argo in sync).
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
├── makefile               # Useful dev commands
└── .env
```

---
