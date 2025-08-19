# api/Dockerfile.dev
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_CACHE_DIR=/app/.uv-cache

WORKDIR /app

# Install system dependencies including dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git build-essential \
  && rm -rf /var/lib/apt/lists/*

# Install uv, the project's package manager
RUN pip install uv

# Create non-root user and group
RUN groupadd -r appuser && useradd -r -g appuser -u 1001 appuser

# Create and set permissions for app directory and cache
RUN mkdir -p /app/.uv-cache && \
    chown -R appuser:appuser /app

# Switch to non-root user for dependency installation
USER appuser

# Copy dependency files (as appuser)
COPY --chown=appuser:appuser pyproject.toml uv.lock* ./

# Install all dependencies including dev dependencies
RUN uv sync --frozen

# Copy application code (as appuser)
COPY --chown=appuser:appuser . /app

EXPOSE 8000

# Use uv run with reload for development
CMD ["uv", "run", "uvicorn", "dpp_api.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]