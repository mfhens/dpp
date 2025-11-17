FROM python:3.13-slim

# Build arguments
ARG ENVIRONMENT=docker
ARG ENABLE_RELOAD=true

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_CACHE_DIR=/app/.uv-cache \
    ENVIRONMENT=${ENVIRONMENT}

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git build-essential tini bash \
 && rm -rf /var/lib/apt/lists/*

# Install uv package manager
RUN pip install --no-cache-dir uv

# Copy dependency files from API folder (context is repo root now)
COPY api/pyproject.toml api/uv.lock* /app/

RUN mkdir -p /app/.uv-cache

# Install all dependencies into /app/.venv
RUN uv sync --frozen

# Copy API source and schemas
COPY api/dpp_api /app/dpp_api
COPY api/main.py /app/main.py
COPY api/startup.sh /app/startup.sh
COPY schemas /app/schemas

# Make startup script executable
RUN chmod +x /app/startup.sh

# Create directories for logs and drop folder
RUN mkdir -p /app/logs /app/drop

# For production/Azure, run as non-root user
# For local dev with Docker secrets, may need root
RUN if [ "$ENVIRONMENT" = "production" ]; then \
        groupadd -r appuser && useradd -r -g appuser appuser && \
        chown -R appuser:appuser /app; \
    fi

# Switch to non-root user in production
USER ${ENVIRONMENT:+appuser}

EXPOSE 8000

ENTRYPOINT ["/usr/bin/tini", "--"]

# Command depends on environment
CMD if [ "$ENVIRONMENT" = "production" ]; then \
        uv run uvicorn dpp_api.main:app --host 0.0.0.0 --port 8000 --workers 4; \
    else \
        uv run uvicorn dpp_api.main:app --host 0.0.0.0 --port 8000 --reload; \
    fi
