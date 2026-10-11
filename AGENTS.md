# AGENTS.md

Welcome to the **SRE Bootcamp - Student API** repository. This document serves as the single operational manual and behavioral contract for AI coding agents working on this codebase.

---

## 🎯 Agent Role & Mission

You are an SRE & Backend Engineering pair programmer assisting with this project. Your mission is to maintain high-quality, production-ready code across both the Django application layer and the infrastructure/deployment pipelines (Docker Compose, Kubernetes, Helm, and GitHub Actions).

### Modular Rules Ingestion
Always load and adhere to the modular guidelines located in the `.agents/rules/` directory:
- [philosophy.md](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/.agents/rules/philosophy.md) - Minimalist Unix-style engineering, simplicity, and architectural constraints.
- [stack.md](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/.agents/rules/stack.md) - Python 3.13, uv, Django 6, DRF, SQLite/PostgreSQL strategies, Gunicorn, and Nginx.
- [cicd.md](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/.agents/rules/cicd.md) - Multi-stage Docker builds, compose topologies, Kubernetes manifests, Helm charts, and CI/CD pipelines.

---

## ⚡ Quick Reference Commands

| Task | Command |
| :--- | :--- |
| **Sync dependencies** | `uv sync` |
| **Run tests (SQLite)** | `uv run python manage.py test --verbosity=2` |
| **Make migrations** | `uv run python manage.py makemigrations` |
| **Apply migrations** | `uv run python manage.py migrate` |
| **Run dev server** | `uv run python manage.py runserver 0.0.0.0:8000` |
| **Add dependency** | `uv add <package>` |
| **Start Docker Compose stack** | `make compose-up` *(or `docker compose up -d`)* |
| **Stop Docker Compose stack** | `make compose-down` *(or `docker compose down`)* |
| **View container logs** | `make compose-logs` *(or `docker compose logs -f`)* |
| **Start 3-node Minikube cluster** | `make minikube-up` |
| **Check Minikube cluster status** | `make minikube-status` |
| **Build & load image into Minikube** | `make minikube-load` |
| **Enable Minikube addons** | `make minikube-addons` |
| **Destroy Minikube cluster** | `make minikube-down` |
| **Apply K8s manifests** | `kubectl apply -f k8s/` |
| **Lint Helm chart** | `helm lint helm/sre-bootcamp` |
| **Deploy with Helm** | `helm upgrade --install sre-bootcamp helm/sre-bootcamp -n sre-bootcamp --create-namespace` |

---

## 📂 Repository Directory Structure

```text
SRE-Bootcamp/
├── .agents/
│   └── rules/
│       ├── philosophy.md         # Engineering philosophy & principles
│       ├── stack.md              # Python, Django, DB & tooling constraints
│       └── cicd.md               # Docker, Compose, K8s, Helm & CI/CD rules
├── .github/
│   └── workflows/
│       ├── docker-ci.yml         # CI/CD: Test, Trivy scan, Docker build/push, EC2 deploy
│       └── k8s-ci.yml            # CI/CD: Test, Trivy scan, Docker build/push, K8s deploy
├── config/
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py               # Decouple-driven settings (SQLite fallback or Postgres)
│   ├── urls.py                   # Root router & redirect to /api/v1/health/
│   └── wsgi.py                   # Production Gunicorn entrypoint
├── core/
│   ├── migrations/               # Database migrations for Student model
│   ├── admin.py
│   ├── apps.py
│   ├── models.py                 # Student model (first_name, last_name, email, etc.)
│   ├── serializers.py            # DRF ModelSerializer for Student
│   ├── tests.py                  # API test suite (Student CRUD & healthcheck)
│   ├── urls.py                   # API routes (/students/, /health/)
│   └── views.py                  # StudentViewSet & HealthCheckView
├── helm/
│   └── sre-bootcamp/             # Parameterized Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── k8s/                          # Raw Kubernetes manifests
│   ├── namespace.yml             # Target namespace: sre-bootcamp
│   ├── postgres.yaml             # Postgres PVC, Deployment, Service
│   ├── web-deployment.yaml       # Django Gunicorn Deployment
│   ├── web-service.yaml          # ClusterIP service for Web
│   ├── nginx-configmap.yaml      # Nginx reverse proxy configuration
│   ├── nginx-deployment.yaml    # Nginx Pod Deployment
│   └── nginx-service.yaml       # Nginx NodePort/LoadBalancer service
├── Dockerfile                    # Multi-stage build (uv builder -> unprivileged runtime)
├── docker-compose.yml            # Local/EC2 orchestration: web, db, nginx, dozzle
├── entrypoint.sh                 # Container startup: optional migrate -> collectstatic -> gunicorn
├── kind-config.yaml              # Local 3-node cluster config (1 control-plane, 2 workers)
├── Makefile                      # Shortcuts for docker-compose and kind operations
├── pyproject.toml                # Dependencies managed via uv
├── uv.lock                       # Deterministic dependency lockfile
├── README.md                     # General repository documentation
├── learn.md                      # Architecture decisions and SRE learning log
├── server-setup.md               # EC2 host provisioning runbook
└── helm.md                       # Comprehensive Helm configuration guide
```

---

## 🏗️ Architecture & Topology

### 1. Application Layer (Django + DRF)
- **Base URL:** `/api/v1/`
- **Endpoints:**
  - `GET /api/v1/health/` - Returns `{ "status": "ok" }` and database connectivity status.
  - `GET, POST /api/v1/students/` - List and create student records.
  - `GET, PUT, PATCH, DELETE /api/v1/students/<id>/` - Retrieve and modify student record.
- **Root redirect:** Visiting `/` redirects automatically to `/api/v1/health/`.

### 2. Deployment Topology
- **Web (`web`):** Django served via Gunicorn (`config.wsgi:application`) on port `8000`.
- **Database (`db`):** PostgreSQL 16 container (`postgres:16-alpine`) on port `5432`.
- **Reverse Proxy (`nginx`):** Nginx container on port `80` routing traffic to `web:8000`.
- **Observability (`dozzle`):** Real-time web log stream exposed on port `8080`.
- **Startup Synchronization:** `web` waits for `db` with `condition: service_healthy` (using `pg_isready`). `entrypoint.sh` executes migrations and `collectstatic` prior to booting Gunicorn.

---

## 🛠️ Workflows & Agent Guidelines

### 1. Python & Dependency Operations
- **Tooling:** Always use `uv`. Never run raw `pip install` or `poetry`.
- When adding or modifying dependencies:
  ```sh
  uv add <package-name>
  ```
- Always verify that [pyproject.toml](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/pyproject.toml) and [uv.lock](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/uv.lock) stay in sync.

### 2. Testing & Quality Checks
- Before proposing or committing any code changes, run the test suite:
  ```sh
  uv run python manage.py test --verbosity=2
  ```
- **Database note during tests:**
  - In `config/settings.py`, Django uses SQLite when `DB_NAME` is empty.
  - If a local `.env` file defines `DB_NAME=sre_bootcamp` (which defaults `DB_HOST=db`), running tests on the local machine outside Docker Compose will attempt to connect to Postgres host `db`.
  - For local standalone unit testing without Docker, ensure `DB_NAME=""` or point `DB_HOST=localhost` if a local Postgres container is running.
  - All model and query additions must remain database-agnostic standard Django ORM code.

### 3. Database Migrations
- If you alter any model in [core/models.py](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/core/models.py):
  1. Generate migrations:
     ```sh
     uv run python manage.py makemigrations core
     ```
  2. Test migration execution:
     ```sh
     uv run python manage.py migrate
     ```
  3. Commit the generated migration file in `core/migrations/`.

### 4. Infrastructure & Manifest Synchronization
When modifying environment variables, ports, or application routes:
1. Update [config/settings.py](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/config/settings.py).
2. Update `.env.example` and `.env.prod.example`.
3. Update [docker-compose.yml](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/docker-compose.yml).
4. Update Kubernetes manifests in [k8s/](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/k8s/).
5. Update Helm templates and `values.yaml` in [helm/sre-bootcamp/](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/helm/sre-bootcamp/).

---

## 🔒 Security & Safe Operations
- **Secrets:** Never write hardcoded credentials, API keys, or production tokens into source files or manifests.
- **Presign Storage:** If object storage is integrated, use AWS S3 with short-lived presigned URLs (`PUT`/`GET`). Never expose public buckets.
- **Production Flags:** Ensure `DEBUG=False` in production manifests, compose setups, and deployment configs.
