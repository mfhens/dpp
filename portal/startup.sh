#!/bin/bash
# Azure App Service startup script for Next.js portal

set -e

echo "Starting DPP Portal on Azure App Service..."
echo "Current directory: $(pwd)"
echo "Contents: $(ls -la)"

# Set default port if not provided by Azure
export PORT=${PORT:-8080}
export HOSTNAME="0.0.0.0"

echo "Port: $PORT"
echo "Checking for Next.js build..."

# Check if .next directory exists
if [ ! -d ".next" ]; then
    echo "ERROR: .next directory not found. Running build..."
    npm run build
fi

# Check for standalone build
if [ -f ".next/standalone/server.js" ]; then
    echo "Using standalone build..."
    # Copy static assets to standalone directory
    if [ -d ".next/static" ]; then
        echo "Copying static assets..."
        cp -r .next/static .next/standalone/.next/
    fi
    if [ -d "public" ]; then
        echo "Copying public assets..."
        cp -r public .next/standalone/
    fi
    cd .next/standalone
    node server.js
else
    echo "No standalone build found. Using next start..."
    npx next start -p $PORT -H $HOSTNAME
fi

