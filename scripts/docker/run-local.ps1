#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple local development setup - API (SQLite) + Portal (Next.js)

.DESCRIPTION
    Runs the DPP system locally with minimal dependencies:
    - API with SQLite database (no Docker required)
    - Portal web server
    - Optional: Seed database with Lego Duck sample data
    
    For full deployment with all services, use: docker compose up

.PARAMETER Seed
    Seed the database with Lego Duck sample data

.PARAMETER Force
    Force re-seed even if data already exists

.EXAMPLE
    .\run-local.ps1
    
.EXAMPLE
    .\run-local.ps1 -Seed
    
.EXAMPLE
    .\run-local.ps1 -Seed -Force
#>

[CmdletBinding()]
param(
    [switch]$Seed,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting DPP Local Development" -ForegroundColor Cyan
Write-Host "==================================`n" -ForegroundColor Cyan

# Check if running from project root
if (-not (Test-Path "api/pyproject.toml")) {
    Write-Error "Please run this script from the project root directory"
    exit 1
}

# ============================================
# 1. Setup API with SQLite
# ============================================
Write-Host "📦 Setting up API..." -ForegroundColor Yellow

Push-Location api

# Check for uv (recommended) or fall back to pip
if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Host "   Installing dependencies with uv..." -ForegroundColor Gray
    uv pip install -e .
} elseif (Get-Command pip -ErrorAction SilentlyContinue) {
    Write-Host "   Installing dependencies with pip..." -ForegroundColor Gray
    pip install -e .
} else {
    Write-Error "Neither 'uv' nor 'pip' found. Please install Python package manager."
    exit 1
}

# Set environment for development mode
$env:ENVIRONMENT = "development"
$env:DATABASE_URL = "sqlite+pysqlite:///./dpp.db"
$env:LOG_LEVEL = "DEBUG"
$env:LOG_TO_FILE = "true"
$env:LOG_FILE = "logs/dpp_api.log"

# Create logs directory if it doesn't exist
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

# Seed database if requested
if ($Seed) {
    Write-Host "   Seeding database with Lego Duck sample data..." -ForegroundColor Cyan
    if ($Force) {
        python -m dpp_api.seed_data --force
    } else {
        python -m dpp_api.seed_data
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to seed database"
        Pop-Location
        exit 1
    }
    Write-Host ""
}

Write-Host "   Starting API server on http://localhost:8000..." -ForegroundColor Green

# Get the current api directory path before popping
$apiPath = (Get-Location).Path

Pop-Location

# Start API in background (from the api directory)
$apiJob = Start-Job -ScriptBlock {
    param($apiPath)
    Set-Location $apiPath
    $env:ENVIRONMENT = "development"
    $env:DATABASE_URL = "sqlite+pysqlite:///./dpp.db"
    $env:LOG_LEVEL = "DEBUG"
    $env:LOG_TO_FILE = "true"
    $env:LOG_FILE = "logs/dpp_api.log"
    
    # Use the venv's uvicorn if available, otherwise system uvicorn
    $uvicornPath = Join-Path $apiPath ".venv/Scripts/uvicorn.exe"
    if (Test-Path $uvicornPath) {
        & $uvicornPath dpp_api.main:app --reload --host 0.0.0.0 --port 8000
    } else {
        uvicorn dpp_api.main:app --reload --host 0.0.0.0 --port 8000
    }
} -ArgumentList $apiPath

# ============================================
# 2. Setup Portal
# ============================================
Write-Host "`n📦 Setting up Portal..." -ForegroundColor Yellow

Push-Location portal

# Check for npm/pnpm
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    Write-Host "   Installing dependencies with pnpm..." -ForegroundColor Gray
    pnpm install
    Write-Host "   Starting Portal on http://localhost:3000..." -ForegroundColor Green
    $portalJob = Start-Job -ScriptBlock {
        param($portalPath)
        Set-Location $portalPath
        pnpm dev
    } -ArgumentList (Get-Location).Path
} elseif (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "   Installing dependencies with npm..." -ForegroundColor Gray
    npm install
    Write-Host "   Starting Portal on http://localhost:3000..." -ForegroundColor Green
    $portalJob = Start-Job -ScriptBlock {
        param($portalPath)
        Set-Location $portalPath
        npm run dev
    } -ArgumentList (Get-Location).Path
} else {
    Write-Warning "npm/pnpm not found. Skipping portal setup."
    $portalJob = $null
}

Pop-Location

# ============================================
# 3. Monitor services
# ============================================
Write-Host "✅ Services Started!" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host "API:    http://localhost:8000" -ForegroundColor Cyan
Write-Host "Docs:   http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "Logs:   api/logs/dpp_api.log" -ForegroundColor Cyan
if ($portalJob) {
    Write-Host "Portal: http://localhost:3000" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "📝 Logging Configuration:" -ForegroundColor Gray
Write-Host "   Level: DEBUG" -ForegroundColor Gray
Write-Host "   File:  api/logs/dpp_api.log" -ForegroundColor Gray
Write-Host ""
if (-not $Seed) {
    Write-Host "💡 Tip: Run with -Seed to load Lego Duck sample data" -ForegroundColor Gray
    Write-Host "   Example: .\run-local.ps1 -Seed" -ForegroundColor Gray
    Write-Host ""
}
Write-Host "Press Ctrl+C to stop all services`n" -ForegroundColor Yellow

# Cleanup function
$cleanup = {
    Write-Host "`n🛑 Stopping services..." -ForegroundColor Yellow
    if ($apiJob) {
        Stop-Job -Job $apiJob -ErrorAction SilentlyContinue
        Remove-Job -Job $apiJob -ErrorAction SilentlyContinue
    }
    if ($portalJob) {
        Stop-Job -Job $portalJob -ErrorAction SilentlyContinue
        Remove-Job -Job $portalJob -ErrorAction SilentlyContinue
    }
    Write-Host "✅ All services stopped" -ForegroundColor Green
}

# Register cleanup on Ctrl+C
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $cleanup | Out-Null

try {
    # Monitor jobs
    while ($true) {
        Start-Sleep -Seconds 2
        
        # Check if jobs are still running
        if ($apiJob.State -eq "Failed") {
            Write-Error "API job failed!"
            Receive-Job -Job $apiJob
            break
        }
        if ($portalJob -and $portalJob.State -eq "Failed") {
            Write-Error "Portal job failed!"
            Receive-Job -Job $portalJob
            break
        }
        
        # Show any output from jobs
        Receive-Job -Job $apiJob -ErrorAction SilentlyContinue
        if ($portalJob) {
            Receive-Job -Job $portalJob -ErrorAction SilentlyContinue
        }
    }
} finally {
    & $cleanup
}
