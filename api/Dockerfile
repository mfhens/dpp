# api/Dockerfile.dev
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_CACHE_DIR=/tmp/uv-cache

WORKDIR /app

# Install system dependencies including dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git build-essential \
  && rm -rf /var/lib/apt/lists/*

# Install uv, the project's package manager
RUN pip install uv

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Install all dependencies including dev dependencies
RUN uv sync --frozen

# Copy application code
COPY . /app

EXPOSE 8000

# Use uv run with reload for development
CMD ["uv", "run", "uvicorn", "dpp_api.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]