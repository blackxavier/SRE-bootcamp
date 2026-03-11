# Learning Log

This document captures key learnings and design decisions as the project evolves.

---

## Dockerization & Deployment

### Why multi-stage Dockerfile?

- **Goal:** Keep the final image small and production-ready.
- We use a **builder stage** to install dependencies (with `uv`) and a separate **runtime stage** that only contains:
  - Python runtime
  - The installed virtual environment (`.venv`)
  - The Django project code.
- This avoids shipping build tools (like `build-essential`) and reduces attack surface and image size.

### Why Gunicorn instead of `runserver`?

- `runserver` is Django's **development server**; it is single-process, not optimized for production, and lacks robustness features.
- **Gunicorn** is a WSGI HTTP server designed for production:
  - Handles multiple workers and concurrent requests.
  - Integrates well with process managers and container orchestration.
- The Docker `CMD` uses:
  - `gunicorn config.wsgi:application --bind 0.0.0.0:8000`
  - This serves the Django app on port 8000 inside the container.

### Environment variables at runtime

- We want configuration (DB credentials, secret keys, debug flags) to be injected **at runtime**, not baked into the image.
- In Docker, we use `-e` flags (or env files) when running containers:
  - Example:
    - `docker run -e DJANGO_SECRET_KEY=... -e DEBUG=False <image>`
- This aligns with the **12-Factor App** principle of storing config in the environment.

### Semver image tagging (no `latest`)

- Instead of using the ambiguous `latest` tag, we:
  - Tag images as `sre-bootcamp-student-api:X.Y.Z`.
  - This makes rollbacks and deployments explicit and reproducible.
- The `Makefile` uses a `VERSION` variable so we can run:
  - `make build VERSION=0.1.0`
  - `make run VERSION=0.1.0`

### Makefile as a UX layer

- The `Makefile` provides **simple commands** to avoid long Docker CLI invocations.
- It documents common workflows:
  - `make build VERSION=0.1.0` → build the image.
  - `make run VERSION=0.1.0` → run the container with sensible env vars.
  - `make push VERSION=0.1.0` → push the image to a registry.
- This becomes a form of living documentation for the team.

### Image size optimizations

- Use `python:3.13-slim` instead of the full Python image.
- Keep build dependencies (like `build-essential`) only in the **builder** stage.
- Clean up `apt` cache (`rm -rf /var/lib/apt/lists/*`) to avoid bloated layers.
- Copy only what is needed into the runtime image:
  - App source code
  - `.venv` from the builder stage
  - No tests, docs, or local artifacts.
- Use a `.dockerignore` file so that local-only files (e.g. `.venv/`, `.git/`,
  editor configs, test artifacts, local databases) are **never** sent in the
  Docker build context. This speeds up builds and reduces the risk of baking
  secrets or junk into images.

### How this all fits together

1. **Build time**
   - Docker builds the image in two stages.
   - `uv sync --frozen` installs dependencies into a virtualenv in the builder stage.
   - The runtime stage only receives the virtualenv and source code.
2. **Run time**
   - Container starts `gunicorn` to serve the Django app.
   - Environment variables control Django settings (e.g., `DJANGO_SECRET_KEY`, `DEBUG`, database connection).
   - The app is ready for container orchestration and cloud deployment.

Future learning entries can extend this document for topics like:
- CI/CD pipelines for building and pushing images.
- Health checks and readiness probes in Kubernetes.
- Observability (logs, metrics, tracing) for the API.

---

## Docker Compose, nginx, and Postgres

### Why docker-compose for this project?

- For many applications, a **single docker-compose stack** (app + DB + proxy)
  is enough for production-like deployments.
- Compose lets us describe the whole system (web, database, reverse proxy)
  in one file and bring it up with a single command.

### Service layout

- `web` (Django + Gunicorn):
  - Built from the local Dockerfile.
  - Uses an entrypoint script to run migrations and `collectstatic` before
    starting Gunicorn.
  - Exposes port 8000 internally for nginx to talk to.
- `db` (Postgres):
  - Uses the official `postgres:16-alpine` image.
  - Stores data in a named Docker volume so container restarts don't
    lose data.
- `nginx`:
  - Uses `nginx:alpine`.
  - Proxies HTTP traffic to `web:8000`.
  - Serves static files from a shared volume mounted at `/static`.

### Entry point script in the container

- The `entrypoint.sh` script does three main things:
  1. Runs `python manage.py migrate --noinput` to apply DB migrations.
  2. Runs `python manage.py collectstatic --noinput` to gather static files
     into `STATIC_ROOT` (`/app/staticfiles`).
  3. Starts Gunicorn with `exec gunicorn config.wsgi:application --bind 0.0.0.0:${PORT}`.
- Using `exec` ensures Gunicorn becomes PID 1 in the container, so signals
  (like SIGTERM) are handled correctly for graceful shutdown.

### nginx as a reverse proxy

- Nginx terminates HTTP connections and forwards requests to the `web`
  container via an upstream block (`server web:8000;`).
- It serves `/static/` URLs directly from the shared `static_volume`, meaning
  Django and Gunicorn don't have to serve static files.
- This separation is closer to real-world production setups and keeps the app
  container focused on dynamic requests.

### Environment-driven configuration

- Django `settings.py` now reads from environment variables:
  - `DJANGO_SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`.
  - `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`.
- In docker-compose, `web` and `db` share consistent DB settings:
  - `web` uses `DB_*` for Django.
  - `db` uses `POSTGRES_*` derived from the same values.
- This matches the 12-Factor "Config" principle and makes it easy to change
  credentials or database hosts per environment.

### Makefile integration

- New targets were added to wrap docker-compose commands:
  - `make compose-up` → `docker compose up --build` (builds images and starts stack).
  - `make compose-down` → `docker compose down` (stops and removes containers).
  - `make compose-logs` → `docker compose logs -f` (tail logs across services).
- This keeps the workflow consistent: developers use `make` for both
  single-container and multi-container flows.

### Minimal but realistic deployment model

- This setup represents a common minimal production-style pattern:
  - One app container (Django + Gunicorn).
  - One database container (Postgres).
  - One reverse proxy/static container (nginx).
- It is simple enough to understand end-to-end, but close to how many
  real services are actually deployed with Docker.

### How Compose handles `build` and `image`

- In `docker-compose.yml` we use both `build: .` and
  `image: sre-bootcamp-student-api:0.1.0` for the `web` service.
- This means:
  - `docker compose build` (or `docker compose up --build`) builds the image
    from the local Dockerfile **and tags it** as `sre-bootcamp-student-api:0.1.0`.
  - Subsequent `docker compose up` runs will reuse that image as long as it
    exists; Compose will rebuild only when explicitly told (`--build`) or when
    the image is missing.
- Using `image:` makes it easy to push/pull the same tagged image to/from a
  registry if needed.

### Handling environment variables in development

- For development, the simplest pattern is to use a local `.env` file in the
  project root. Docker Compose automatically reads it and substitutes
  `${VAR_NAME}` expressions in `docker-compose.yml`.
- We keep `.env` out of version control (via `.gitignore`) and optionally
  maintain a `.env.example` so others know which variables to set.
- Example dev `.env`:

  ```env
  DJANGO_SECRET_KEY=dev-secret-change-me
  DEBUG=True
  DB_NAME=sre_bootcamp
  DB_USER=postgres
  DB_PASSWORD=postgres
  ```

### Private network and port exposure

- All services (`web`, `db`, `nginx`) are attached to a custom `backend`
  network. Containers on this network can reach each other by service name
  (e.g., `web`, `db`).
- We do **not** publish ports for `web` or `db` to the host:
  - `web` listens on `8000` but only inside the network.
  - `db` listens on `5432` but is only reachable from other containers.
- Only `nginx` publishes `80:80`, making it the single public entrypoint. This
  matches the idea that the app and database are internal, while nginx is the
  external-facing proxy.

### Log visibility with Dozzle

- Dozzle is added as a helper service in `docker-compose.yml`:
  - It runs the `amir20/dozzle` image and mounts `/var/run/docker.sock`.
  - This socket mount allows Dozzle to read logs from all Docker containers on
    the local Docker engine.
  - It publishes `8080:8080`, so the UI is reachable at
    `http://localhost:8080`.
- This provides a simple, browser-based way to tail logs across `web`, `db`,
  `nginx`, and other containers, which is useful when learning and debugging
  Docker-based systems.
