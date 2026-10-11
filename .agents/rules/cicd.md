# CI/CD, Containerization & Infrastructure Guidelines

This document details standards for containerization, local orchestration, CI/CD pipelines, and infrastructure deployment (EC2, Docker Compose, Kubernetes, and Helm).

---

## 🐳 Containerization Standards

1. **Multi-Stage `Dockerfile`**
   - **Base Image:** `python:3.13-slim`.
   - **Stage 1 (`builder`):**
     - Extracts the `uv` binary directly from `ghcr.io/astral-sh/uv:latest`.
     - Installs dependencies from `pyproject.toml` and `uv.lock` with `uv sync --frozen --no-install-project --no-dev`.
     - Copies app source and synchronizes runtime dependencies.
   - **Stage 2 (`runtime`):**
     - Keeps image footprint minimal and secure.
     - Installs only essential system packages (e.g., `curl` for healthchecks).
     - Copies the built virtualenv (`/app/.venv`) and minimal source code (`config/`, `core/`, `manage.py`, `entrypoint.sh`).
     - Uses `entrypoint.sh` for lifecycle management.

2. **Container Lifecycle (`entrypoint.sh`)**
   - Automatically executes:
     1. Database migrations: `python manage.py migrate --noinput`
     2. Static file collection: `python manage.py collectstatic --noinput`
     3. WSGI Server: `exec gunicorn config.wsgi:application --bind 0.0.0.0:${PORT}`

---

## 📦 Local Orchestration (`docker-compose.yml`)

- **Services:**
  - `web`: Application container running Gunicorn on port 8000.
  - `db`: PostgreSQL 16 container (`postgres:16-alpine`) on internal network.
  - `nginx`: Reverse proxy routing port 80 to `web:8000`.
  - `dozzle`: Real-time web log viewer exposed on port 8080.
- **Reliable Startup Pattern:**
  - `db` defines a healthcheck using `pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB`.
  - `web` uses `depends_on: db: condition: service_healthy` to guarantee Postgres is accepting connections before migrations and Gunicorn start.
- **Makefile Targets:**
  - `make compose-up`: Start stack detached (`docker compose up -d`).
  - `make compose-down`: Stop stack (`docker compose down`).
  - `make compose-logs`: Tail logs in real time (`docker compose logs -f`).

---

## ☸️ Kubernetes & Helm Architecture

### Local Multi-Node Cluster (`minikube`)
- 3-node topology: Started with `make minikube-up` using `--nodes=3 --cpus=2 --memory=4096`.
- Profile name: `sre-bootcamp`.
- Local workflows:
  - Cluster lifecycle: `make minikube-up`, `make minikube-down`
  - Ingress & Addons: `make minikube-addons` (enables ingress and default-storageclass)
  - Fast iteration: `make minikube-load` (builds `sre-bootcamp-web:local` and loads directly via `minikube image load`)
  - Storage: Utilizes minikube's built-in `default-storageclass` backed by host path.

### Kubernetes Manifests (`k8s/`)
- Target namespace: `sre-bootcamp` ([namespace.yml](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/k8s/namespace.yml)).
- Components:
  - Database: `postgres.yaml` (StatefulSet + Headless Service).
  - Application: `web-deployment.yaml` and `web-service.yaml` (readiness & liveness probes on `/api/v1/health/`).
  - Proxy: `nginx-configmap.yaml`, `nginx-deployment.yaml`, `nginx-service.yaml` (NodePort/LoadBalancer).

### Helm Packaging (`helm/sre-bootcamp/`)
- Packaged chart under `helm/sre-bootcamp/`.
- Configurable values in `values.yaml` for replica counts, resource limits, image repositories/tags, and ingress/service types.
- Standard deployment command:
  ```sh
  helm upgrade --install sre-bootcamp helm/sre-bootcamp -n sre-bootcamp --create-namespace
  ```

---

## 🔄 CI/CD Automation (GitHub Actions)

Workflows are located in `.github/workflows/`:

1. **Docker / EC2 Pipeline (`docker-ci.yml`)**
   - Trigger: Push to `docker` branch.
   - Stage 1: Setup Python 3.13 + `astral-sh/setup-uv` (with caching enabled). Runs Django tests against ephemeral PostgreSQL service.
   - Stage 2: Security scanning via Trivy.
   - Stage 3: Multi-arch / cached Docker build and publication to GitHub Container Registry (GHCR).
   - Stage 4: Remote EC2 deployment triggering `docker compose pull && docker compose up -d`.

2. **Kubernetes Pipeline (`k8s-ci.yml`)**
   - Trigger: Push to `dev`, semver tags (`v*`), or manual `workflow_dispatch`.
   - Stage 1: Test & lint via `uv`.
   - Stage 2: Trivy security scan on filesystem and image.
   - Stage 3: Build & push container image to GHCR.
   - Stage 4: Deploy / rollout update to Kubernetes cluster via Helm or `kubectl rollout restart`.

---

## 🛡️ Pipeline & Quality Rules for Agents

- **Always run tests before pushing changes:** Run tests locally using SQLite (`uv run python manage.py test`) or against Postgres.
- **Keep locks reproducible:** Any dependency addition in `pyproject.toml` MUST update `uv.lock` via `uv lock`.
- **Manifest consistency:** Any change to container ports or environment variable names must be synchronized across:
  1. `config/settings.py`
  2. `docker-compose.yml`
  3. `k8s/*.yaml`
  4. `helm/sre-bootcamp/values.yaml` and `templates/`
