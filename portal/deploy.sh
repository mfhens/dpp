#!/bin/bash
# Azure App Service deployment script for Next.js portal

set -e

echo "=========================================="
echo "DPP Portal - Azure Deployment Script"
echo "=========================================="
echo "Current directory: $(pwd)"
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm ci --production=false
echo "✅ Dependencies installed"
echo ""

# Build the application
echo "🔨 Building Next.js application..."
echo "   - Compiling TypeScript"
echo "   - Processing Tailwind CSS"
echo "   - Optimizing for production"
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully"
else
    echo "❌ Build failed"
    exit 1
fi

# Verify build output
echo ""
echo "📂 Verifying build output..."
if [ -d ".next" ]; then
    echo "✅ .next directory exists"
    echo "   Contents:"
    ls -la .next/ | head -20
else
    echo "❌ .next directory not found"
    exit 1
fi

# Check for CSS files
if [ -d ".next/static/css" ]; then
    echo "✅ CSS files generated:"
    ls -lh .next/static/css/
else
    echo "⚠️  No CSS directory found in .next/static/"
fi

echo ""
echo "=========================================="
echo "✅ Deployment preparation complete"
echo "=========================================="
