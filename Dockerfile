
# ---------------------
# 1. Builder stage
# ---------------------
FROM python:3.13-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# System deps for building Python packages (if needed later)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv in the builder image
RUN pip install --no-cache-dir uv

# Copy dependency files first to leverage Docker layer caching
COPY pyproject.toml uv.lock ./

# Create virtualenv and install dependencies using uv
RUN uv sync --frozen --no-install-project

# Copy the rest of the application code
COPY . .


FROM python:3.13-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_HOME=/app \
    DJANGO_SETTINGS_MODULE=config.settings \
    PORT=8000

WORKDIR ${APP_HOME}

# Install runtime OS deps only (keep image small)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the virtual environment from the builder
COPY --from=builder /app/.venv ./.venv

# Copy only the app source code (no venv, no caches)
COPY --from=builder /app/config ./config
COPY --from=builder /app/core ./core
COPY --from=builder /app/manage.py ./manage.py
COPY ./entrypoint.sh ./entrypoint.sh

# Ensure the venv Python and scripts are on PATH
ENV PATH="/app/.venv/bin:$PATH"

RUN chmod +x ./entrypoint.sh

# Expose the application port
EXPOSE ${PORT}

ENTRYPOINT ["./entrypoint.sh"]
