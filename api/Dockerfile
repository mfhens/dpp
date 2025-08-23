FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_CACHE_DIR=/app/.uv-cache

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git build-essential tini \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir uv

# Copy dependency files from API folder (context is repo root now)
COPY api/pyproject.toml api/uv.lock* /app/

RUN mkdir -p /app/.uv-cache

# Install all deps (dev included) into /app/.venv
RUN uv sync --frozen

# Copy API source and schemas
COPY api/dpp_api /app/dpp_api
COPY api/main.py /app/main.py
COPY schemas /app/schemas

# Run as root in dev so it can read /run/secrets/*
USER root

EXPOSE 8000
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["uv", "run", "uvicorn", "dpp_api.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
