# SRE Bootcamp - Student API

A simple Django REST Framework API for managing student records.

## Tech Stack

- Python 3.13+
- Django 6.0
- Django REST Framework
- SQLite (development)
- uv (package manager)

## Quick Start (Local with uv)

```sh
# Clone the repository
git clone https://github.com/yourusername/SRE-Bootcamp.git
cd SRE-Bootcamp

# Install dependencies
uv sync

# Run migrations
uv run python manage.py migrate

# Start development server
uv run python manage.py runserver
```

## Running with Docker

This project ships with a multi-stage Dockerfile and a Makefile for convenience.

### Build the image

Use a **semantic version** tag (no `latest`):

```sh
make build VERSION=0.1.0
```

This builds an image named `sre-bootcamp-student-api:0.1.0`.

### Run the container

Inject configuration via environment variables at runtime:

```sh
make run VERSION=0.1.0
```

This is equivalent to:

```sh
docker run --rm -p 8000:8000 \
  -e DJANGO_SECRET_KEY="changeme" \
  -e DEBUG="False" \
  -e DB_NAME="sre_bootcamp" \
  -e DB_USER="postgres" \
  -e DB_PASSWORD="postgres" \
  -e DB_HOST="localhost" \
  -e DB_PORT="5432" \
  sre-bootcamp-student-api:0.1.0
```

Once running, the API is available at:

- `http://localhost:8000/api/v1/students/`
- `http://localhost:8000/api/v1/health/`

## Running with Docker Compose (nginx + Postgres)

For a more production-like setup, this project includes a `docker-compose.yml`
that runs multiple services:

- `web`: Django app served by Gunicorn
- `db`: PostgreSQL database
- `nginx`: reverse proxy in front of Gunicorn and static files server
- `dozzle`: lightweight web UI for viewing Docker container logs

### Start the stack

```sh
docker compose up --build
```

Or via Makefile:

```sh
make compose-up
```

The API will be available at:

- `http://localhost/api/v1/students/`
- `http://localhost/api/v1/health/`

### Environment configuration

You can override defaults using a `.env` file or shell env vars. Key variables:

- `DJANGO_SECRET_KEY` – Django secret key
- `DEBUG` – `True` or `False` (default: `False` in compose)
- `DB_NAME`, `DB_USER`, `DB_PASSWORD` – database credentials

`web` reads `DB_*` variables, and `db` uses the same values as `POSTGRES_*`
so both containers share the same database configuration.

For local development convenience, create a `.env` file (ignored by git) in
the project root:

```env
DJANGO_SECRET_KEY=dev-secret-change-me
DEBUG=True
DB_NAME=sre_bootcamp
DB_USER=postgres
DB_PASSWORD=postgres
```

Docker Compose will load these values automatically and pass them to the
containers.

### Viewing logs with Dozzle

When running via docker-compose, Dozzle will be available at:

- `http://localhost:8080`

It provides a live, filterable view of all Docker container logs on your
machine (requires access to the Docker socket).

## API Endpoints

Base URL: `http://localhost:8000/api/v1/`

### Students

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/students/` | List all students |
| POST | `/api/v1/students/` | Create a new student |
| GET | `/api/v1/students/{id}/` | Get student by ID |
| PUT | `/api/v1/students/{id}/` | Update student (full) |
| PATCH | `/api/v1/students/{id}/` | Update student (partial) |
| DELETE | `/api/v1/students/{id}/` | Delete student |

### Health Check

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/health/` | Health check with DB status |

## Example Requests

### Create a Student

```sh
curl -X POST http://localhost:8000/api/v1/students/ \
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
curl http://localhost:8000/api/v1/students/
```

### Health Check

```sh
curl http://localhost:8000/api/v1/health/
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
uv run python manage.py test
```

## Project Structure

```
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
├── docker-compose.yml  # nginx + Gunicorn + Postgres stack
├── nginx.conf          # Nginx reverse proxy and static config
├── entrypoint.sh       # Container entrypoint (migrate + collectstatic + Gunicorn)
├── manage.py
├── pyproject.toml      # Dependencies
└── uv.lock             # Locked dependencies
```

## API Versioning

This API uses URL path versioning. Current version: `v1`

To add new versions, update `ALLOWED_VERSIONS` in `config/settings.py`.

## License

MIT
