# Technology Stack & Tooling Guidelines

This document outlines the required language, framework, database, and toolchain standards for this project.

---

## 🐍 Python & Dependency Management

- **Runtime:** Python 3.13+ (`.python-version`).
- **Tooling:** **ALWAYS use `uv`** for all Python and virtual environment operations.
  - Install / Sync dependencies: `uv sync`
  - Run scripts / commands: `uv run <command>` (e.g., `uv run python manage.py test`)
  - Add dependencies: `uv add <package>`
  - Add dev dependencies: `uv add --dev <package>`
  - Lock dependencies: `uv lock`
  - **PROHIBITED:** Never invoke raw `pip install`, `virtualenv`, or `poetry`.
- **Dependencies file:** Maintain dependencies in [pyproject.toml](file:///c:/Users/New/Documents/Chiefbuilder/SRE-Bootcamp/pyproject.toml) and commit updates to `uv.lock`. Keep dependencies minimal.

---

## 🌐 Application & Web Architecture

- **Framework:** Django 6.0+ with Django REST Framework (DRF).
- **Application Structure:**
  - `config/`: Project configuration, URL routing, settings, WSGI/ASGI entrypoints.
  - `core/`: Primary Django application holding models, serializers, views, and tests for student management and health checks.
- **Routing & Versioning:**
  - All API routes are version-prefixed (e.g., `/api/v1/students/`, `/api/v1/health/`).
  - Root URL (`/`) redirects to `/api/v1/health/`.
- **WSGI Application Server:** Gunicorn (`config.wsgi:application`) bound to `0.0.0.0:${PORT:-8000}`.
- **Reverse Proxy:** Nginx acts as the public reverse proxy routing incoming port 80 traffic to Gunicorn on port 8000.
- **Static Assets:** Handled via WhiteNoise (`whitenoise.middleware.WhiteNoiseMiddleware`) with `python manage.py collectstatic --noinput`.

---

## 🗄️ Database Strategy

- **Dynamic Database Switching:**
  - Controlled via `python-decouple` in `config/settings.py` based on `DB_NAME`.
  - **Local Development & Fast Testing:** Default to **SQLite** (`BASE_DIR / 'db.sqlite3'`) when `DB_NAME` is unset or empty.
  - **Container & Production Workloads:** Default to **PostgreSQL** when `DB_NAME` is provided (`POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT`).
  - *Gotcha:* If a local `.env` has `DB_NAME` set and `DB_HOST=db`, local standalone test runs will look for the container host `db`. Clear `DB_NAME` or point `DB_HOST=localhost` for local execution.
- **ORM Standard:**
  - Code must remain strictly database-agnostic using standard Django ORM.
  - Avoid database-specific raw SQL to ensure seamless switching between SQLite (tests) and PostgreSQL (production).
  - All schema changes must be accompanied by versioned Django migrations (`core/migrations/`).

---

## ⚙️ Configuration & Environment Management

- Configuration is managed using `python-decouple.AutoConfig` loaded relative to `BASE_DIR`.
- Standard environment variables:
  - `DJANGO_SECRET_KEY`: Django cryptographic signing key.
  - `DEBUG`: Boolean flag (`False` in production).
  - `ALLOWED_HOSTS`: Comma-separated list of allowed hostnames/IPs.
  - `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`: Database connection details.
  - `PORT`: HTTP port for Gunicorn (defaults to `8000`).
  - `WEB_IMAGE`: Docker image tag for deployments.
- Reference templates: `.env.example` (local development) and `.env.prod.example` (production/EC2).
