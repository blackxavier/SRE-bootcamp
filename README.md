# SRE Bootcamp - Student API

A simple Django REST Framework API for managing student records.

## Tech Stack

- Python 3.13+
- Django 6.0
- Django REST Framework
- SQLite (development)
- uv (package manager)

## Quick Start

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
├── manage.py
├── pyproject.toml      # Dependencies
└── uv.lock             # Locked dependencies
```

## API Versioning

This API uses URL path versioning. Current version: `v1`

To add new versions, update `ALLOWED_VERSIONS` in `config/settings.py`.

## License

MIT
