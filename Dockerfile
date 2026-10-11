
# ---------------------
# 1. Builder stage
# ---------------------
FROM python:3.13-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app

# Pull uv binary directly from the official image - no pip needed
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Install dependencies first (separate layer for cache reuse)
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev

# Copy application source and install the project itself
COPY . .
RUN uv sync --frozen --no-dev


# ---------------------
# 2. Runtime stage
# ---------------------
FROM python:3.13-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_HOME=/app \
    DJANGO_SETTINGS_MODULE=config.settings \
    PORT=8000 \
    PATH="/app/.venv/bin:$PATH"

WORKDIR ${APP_HOME}

# curl is the only runtime OS dep (healthchecks / debugging)
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Create unprivileged system user and group (appuser:10001)
RUN groupadd -g 10001 appgroup \
    && useradd -u 10001 -g appgroup -s /bin/sh -d ${APP_HOME} appuser

# Pre-create application directories and configure ownership
RUN mkdir -p ${APP_HOME}/staticfiles \
    && chown -R 10001:10001 ${APP_HOME}

# Copy the virtual environment from builder with unprivileged ownership
COPY --chown=10001:10001 --from=builder /app/.venv ./.venv

# Copy only the application source with unprivileged ownership
COPY --chown=10001:10001 --from=builder /app/config ./config
COPY --chown=10001:10001 --from=builder /app/core ./core
COPY --chown=10001:10001 --from=builder /app/manage.py ./manage.py
COPY --chown=10001:10001 ./entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

# Switch to unprivileged runtime user
USER 10001:10001

# Expose the application port
EXPOSE ${PORT}

ENTRYPOINT ["./entrypoint.sh"]
