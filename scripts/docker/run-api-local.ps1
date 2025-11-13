#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run DPP API locally in development mode
.DESCRIPTION
    This script runs the DPP API locally with SQLite and mock services for development.
    Perfect for quick iteration and testing without Docker.
.PARAMETER Port
    The port to run the API on (default: 8000)
.PARAMETER Reload
    Enable auto-reload on code changes (default: true)
.PARAMETER LogLevel
    Logging level: DEBUG, INFO, WARNING, ERROR (default: INFO)
.EXAMPLE
    .\run-api-local.ps1
.EXAMPLE
    .\run-api-local.ps1 -Port 8080 -LogLevel DEBUG
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Port = 8000,
    
    [Parameter(Mandatory=$false)]
    [bool]$Reload = $true,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
    [string]$LogLevel = "INFO"
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Warning { Write-Host "⚠️  $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "❌ $args" -ForegroundColor Red }

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
Write-Host "  DPP API - Local Development Mode" -ForegroundColor Blue
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
Write-Host ""

# Navigate to API directory
$ScriptDir = $PSScriptRoot
$ApiDir = Join-Path $ScriptDir "api"

if (-not (Test-Path $ApiDir)) {
    Write-Error "API directory not found: $ApiDir"
    exit 1
}

Set-Location $ApiDir

Write-Info "API Directory: $ApiDir"
Write-Info "Port: $Port"
Write-Info "Auto-reload: $Reload"
Write-Info "Log level: $LogLevel"
Write-Host ""

# Check if uv is installed
Write-Info "Checking for uv..."
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Error "uv is not installed. Please install it first:"
    Write-Host "  pip install uv"
    Write-Host "  or visit: https://github.com/astral-sh/uv"
    exit 1
}
Write-Success "uv found"

# Check if venv exists, create if not
Write-Info "Checking Python environment..."
if (-not (Test-Path ".venv")) {
    Write-Info "Creating virtual environment..."
    uv venv
    Write-Success "Virtual environment created"
}

# Install dependencies
Write-Info "Installing dependencies..."
uv sync
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to install dependencies"
    exit 1
}
Write-Success "Dependencies installed"
Write-Host ""

# Set development environment variables
Write-Info "Configuring development environment..."
$env:ENVIRONMENT = "development"
$env:DATABASE_URL = "sqlite+pysqlite:///./dpp.db"
$env:LOG_LEVEL = $LogLevel
$env:LOG_TO_FILE = "true"
$env:LOG_FILE = "logs/dpp_api.log"
$env:PUBLIC_PORTAL_BASE = "http://localhost:3000"
$env:ENABLE_FILE_WATCHER = "true"

# Development mode: disable auth, use stubs
$env:OIDC_ISSUER_URL = "http://localhost:8080/realms/dpp"
$env:OIDC_AUDIENCE = "dpp-api"

Write-Success "Environment configured for local development"
Write-Host ""
Write-Warning "Running in DEVELOPMENT mode:"
Write-Host "  • Using SQLite database (dpp.db)"
Write-Host "  • Authentication may be bypassed"
Write-Host "  • External services may use mock implementations"
Write-Host "  • File watcher enabled for Planning Insights"
Write-Host ""

# Create logs directory
$LogsDir = Join-Path $ApiDir "logs"
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

# Create drop directory for file watcher
$DropDir = Join-Path $ApiDir "drop"
if (-not (Test-Path $DropDir)) {
    New-Item -ItemType Directory -Path $DropDir | Out-Null
    Write-Info "Created drop folder: $DropDir"
}

# Display startup info
Write-Host ""
Write-Success "Starting DPP API..."
Write-Host ""
Write-Info "API URL: http://localhost:$Port"
Write-Info "API Docs: http://localhost:$Port/docs"
Write-Info "OpenAPI: http://localhost:$Port/openapi.json"
Write-Info "Drop folder: $DropDir"
Write-Host ""
Write-Info "Press Ctrl+C to stop"
Write-Host ""
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

# Run the API
$reloadFlag = if ($Reload) { "--reload" } else { "" }

uv run uvicorn dpp_api.main:app `
    --host 0.0.0.0 `
    --port $Port `
    --log-level $LogLevel.ToLower() `
    $reloadFlag

Write-Host ""
Write-Info "API stopped"
