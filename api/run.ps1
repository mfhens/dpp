# Run API Server
# Make sure PostgreSQL is running first: docker compose -f ..\compose.local-dev.yaml up -d

Write-Host "🚀 Starting DPP API Server" -ForegroundColor Cyan
Write-Host ""

# Check if PostgreSQL is running
Write-Host "Checking PostgreSQL..." -ForegroundColor Yellow
try {
    $pgStatus = docker compose -f ..\compose.local-dev.yaml ps postgres --format json | ConvertFrom-Json
    if ($pgStatus.State -eq "running") {
        Write-Host "✓ PostgreSQL is running" -ForegroundColor Green
    } else {
        Write-Host "✗ PostgreSQL is not running!" -ForegroundColor Red
        Write-Host "  Run: docker compose -f ..\compose.local-dev.yaml up -d" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ PostgreSQL is not running!" -ForegroundColor Red
    Write-Host "  Run: docker compose -f ..\compose.local-dev.yaml up -d" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Check/create virtual environment
if (-not (Test-Path .venv\Scripts\python.exe)) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv .venv
    Write-Host "✓ Virtual environment created" -ForegroundColor Green
    Write-Host ""
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
. .venv\Scripts\Activate.ps1

# Load environment variables from .env file
if (Test-Path .env) {
    Write-Host "Loading environment variables..." -ForegroundColor Yellow
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            if ($name -and -not $name.StartsWith('#')) {
                [Environment]::SetEnvironmentVariable($name, $value, 'Process')
            }
        }
    }
    Write-Host "✓ Environment variables loaded" -ForegroundColor Green
}

# Install dependencies if needed
Write-Host "Checking dependencies..." -ForegroundColor Yellow
pip show fastapi > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    pip install -e .
}
Write-Host "✓ Dependencies ready" -ForegroundColor Green

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Starting API Server" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  URL:  http://localhost:8000" -ForegroundColor White
Write-Host "  Docs: http://localhost:8000/docs" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

# Run the API with auto-reload
uvicorn dpp_api.main:app --host localhost --port 8000 --reload
