#!/bin/bash
# Startup script for Azure App Service deployment
# This script handles initialization and starts the FastAPI application

set -e

echo "🚀 Starting DPP API on Azure App Service..."

# Check Python version
echo "Python version: $(python --version)"

# Install uv if not present
if ! command -v uv &> /dev/null; then
    echo "📦 Installing uv..."
    pip install uv
fi

# Install dependencies
echo "📦 Installing dependencies..."
uv sync --frozen

# Run database migrations if needed
echo "🗄️  Initializing database..."
# Database will be initialized on first startup via FastAPI startup event

# Start the application with production settings
echo "✅ Starting uvicorn server..."
exec uv run uvicorn dpp_api.main:app \
    --host 0.0.0.0 \
    --port "${PORT:-8000}" \
    --workers "${WORKERS:-4}" \
    --log-level info \
    --no-access-log
