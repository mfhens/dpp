#!/bin/bash
# Azure App Service startup script for Next.js portal

set -e

echo "=========================================="
echo "DPP Portal - Azure App Service Startup"
echo "=========================================="
echo "Current directory: $(pwd)"
echo "Node version: $(node -v)"

# Set default port if not provided by Azure
export PORT=${PORT:-8080}
export HOSTNAME="0.0.0.0"

echo "Port: $PORT"
echo "Hostname: $HOSTNAME"
echo ""

# Verify build exists
if [ ! -d ".next" ]; then
    echo "❌ ERROR: .next directory not found!"
    echo "Build should have been completed during deployment."
    exit 1
fi

echo "✅ Build directory found"
echo ""

# Verify CSS files exist
echo "🎨 Checking CSS files..."
if [ -d ".next/static/css" ]; then
    echo "✅ CSS files found:"
    ls -lh .next/static/css/ || echo "   (Directory exists but may be empty)"
else
    echo "⚠️  Warning: No CSS directory found!"
fi

# List all static assets
echo ""
echo "📂 Static assets:"
if [ -d ".next/static" ]; then
    ls -lh .next/static/ || echo "   (Directory exists but may be empty)"
fi
echo ""

# Start the Next.js server
echo "🚀 Starting Next.js server..."
echo "   Using: node server.js"
echo "=========================================="
echo ""

exec node server.js

