# SRE Bootcamp - Student API

A simple Django REST Framework API for managing student records.

## Tech Stack

- Python 3.13+
- uv
- Django 6.0
- Django REST Framework
- python-decouple
- PostgreSQL
- Docker Compose

## Deployment Model

This repository is intended to run as a Docker Compose stack on an EC2-based
development server.

The deployment topology is:

- `web`: Django app served by Gunicorn
- `db`: PostgreSQL database
- `nginx`: reverse proxy in front of Gunicorn and static files
- `dozzle`: live container log viewer

The single source of truth for orchestration is `docker-compose.yml`.

## Deploying on EC2

The GitHub Actions workflow builds and publishes the application image, then the
EC2 host pulls that image and starts the stack with Docker Compose.

Project dependencies are managed with `uv`, and Django settings read
configuration through `python-decouple` from the environment or `.env`-style
files.

### Required environment variables

Provide these values on the EC2 host through `.env.prod` or your deployment
automation:

- `DJANGO_SECRET_KEY`
- `DEBUG`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `DB_HOST`
- `DB_PORT`
- `ALLOWED_HOSTS`
- `WEB_IMAGE`

Use `.env.example` as the starting template for these values.

`WEB_IMAGE` should point at the published container image tag that EC2 should
run, for example `docker.io/<user>/sre-bootcamp-web:dev-abc1234`.

### Start the stack

```sh
docker compose --env-file .env.prod --env-file .image.env up -d
```

Or via Makefile:

```sh
make compose-up
```

```sh
make compose-logs
```

Once running on the EC2 host, the API is available at:

- `http://<ec2-host>/api/v1/students/`
- `http://<ec2-host>/api/v1/health/`

Dozzle is exposed at:

- `http://<ec2-host>:8080`

## Why startup is reliable now

The web container runs database migrations during startup. Previously, Compose
only guaranteed that the Postgres container process had been started, not that
Postgres was ready to accept connections.

`docker-compose.yml` now adds a PostgreSQL healthcheck using `pg_isready`, and
the `web` service waits on `db` with `condition: service_healthy`. That means
Gunicorn and migrations only start after Postgres is actually ready.

## API Endpoints

Base URL: `http://<ec2-host>/api/v1/`

### Students

| Method | Endpoint | Description |
| ------ | -------- | ----------- |
| GET | `/api/v1/students/` | List all students |
| POST | `/api/v1/students/` | Create a new student |
| GET | `/api/v1/students/{id}/` | Get student by ID |
| PUT | `/api/v1/students/{id}/` | Update student (full) |
| PATCH | `/api/v1/students/{id}/` | Update student (partial) |
| DELETE | `/api/v1/students/{id}/` | Delete student |

### Health Check

| Method | Endpoint | Description |
| ------ | -------- | ----------- |
| GET | `/api/v1/health/` | Health check with DB status |

## Example Requests

### Create a Student

```sh
curl -X POST http://<ec2-host>/api/v1/students/ \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "date_of_birth": "2000-01-15"
  }'
```

### Get All Students

```sh
curl http://<ec2-host>/api/v1/students/
```

### Check Service Health

```sh
curl http://<ec2-host>/api/v1/health/
```

Response:

```json
{
  "status": "healthy",
  "version": "v1",
  "database": "connected"
}
```

## Running Tests

```sh
uv sync
uv run python manage.py test
```

## Project Structure

```text
SRE-Bootcamp/
├── config/             # Django project settings
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── core/               # Main application
│   ├── models.py       # Student model
│   ├── serializers.py  # DRF serializers
│   ├── views.py        # API views
│   ├── urls.py         # App URLs
│   └── tests.py        # Unit tests
├── Dockerfile          # Multi-stage build for app image
├── docker-compose.yml  # EC2 deployment stack
├── nginx.conf          # Nginx reverse proxy and static config
├── entrypoint.sh       # Container entrypoint (migrate + collectstatic + Gunicorn)
├── manage.py
├── pyproject.toml      # Dependencies
└── uv.lock             # Locked dependencies for image builds
```

## API Versioning

This API uses URL path versioning. Current version: `v1`

To add new versions, update `ALLOWED_VERSIONS` in `config/settings.py`.

## License

MIT
