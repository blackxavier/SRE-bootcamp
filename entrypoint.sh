#!/usr/bin/env sh
set -e

# Default port if not set
: "${PORT:=8000}"

# Migration toggle: false by default for stateless pods in K8s.
# Set RUN_MIGRATIONS=true for standalone local Compose setups.
: "${RUN_MIGRATIONS:=false}"
: "${COLLECT_STATIC:=true}"

if [ "$RUN_MIGRATIONS" = "true" ] || [ "$RUN_MIGRATIONS" = "1" ]; then
    echo "[entrypoint] Applying database migrations..."
    python manage.py migrate --noinput
else
    echo "[entrypoint] Skipping database migrations (RUN_MIGRATIONS=${RUN_MIGRATIONS})..."
fi

if [ "$COLLECT_STATIC" = "true" ] || [ "$COLLECT_STATIC" = "1" ]; then
    echo "[entrypoint] Collecting static files..."
    python manage.py collectstatic --noinput
else
    echo "[entrypoint] Skipping collectstatic (COLLECT_STATIC=${COLLECT_STATIC})..."
fi

echo "[entrypoint] Starting Gunicorn on port ${PORT} as user $(id -u -n)..."
exec gunicorn config.wsgi:application --bind 0.0.0.0:${PORT}
