#!/usr/bin/env sh
set -e

# Default port if not set
: "${PORT:=8000}"

echo "[entrypoint] Applying database migrations..."
python manage.py migrate --noinput

echo "[entrypoint] Collecting static files (if needed)..."
python manage.py collectstatic --noinput

echo "[entrypoint] Starting Gunicorn on port ${PORT}..."
exec gunicorn config.wsgi:application --bind 0.0.0.0:${PORT}
