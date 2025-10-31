# Start Local Development Environment
# This script starts PostgreSQL in Docker and provides instructions for running API and Portal locally

Write-Host "🚀 Starting Local Development Environment" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check if secrets exist
Write-Host ""
Write-Host "Checking secrets..." -ForegroundColor Yellow
if (-not (Test-Path "secrets\postgres_user.txt")) {
    Write-Host "✗ Secrets not found. Running setup-secrets.ps1..." -ForegroundColor Yellow
    .\setup-secrets.ps1
}
Write-Host "✓ Secrets found" -ForegroundColor Green

# Start PostgreSQL
Write-Host ""
Write-Host "Starting PostgreSQL..." -ForegroundColor Yellow
docker compose -f compose.local-dev.yaml up -d

# Wait for PostgreSQL to be healthy
Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
while ($attempt -lt $maxAttempts) {
    $health = docker compose -f compose.local-dev.yaml ps --format json | ConvertFrom-Json | Where-Object { $_.Service -eq "postgres" } | Select-Object -ExpandProperty Health
    if ($health -eq "healthy") {
        Write-Host "✓ PostgreSQL is ready" -ForegroundColor Green
        break
    }
    $attempt++
    Start-Sleep -Seconds 2
    Write-Host "  Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
}

if ($attempt -eq $maxAttempts) {
    Write-Host "✗ PostgreSQL failed to become healthy" -ForegroundColor Red
    Write-Host "Check logs with: docker compose -f compose.local-dev.yaml logs postgres" -ForegroundColor Yellow
    exit 1
}

# Display instructions
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PostgreSQL is running! Now start the API and Portal:" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "📘 Terminal 1 - Start API:" -ForegroundColor Blue
Write-Host "  cd api" -ForegroundColor White
Write-Host "  uv venv" -ForegroundColor White
Write-Host "  .venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host "  uv pip install -e ." -ForegroundColor White
Write-Host "  `$env:DATABASE_URL='$(Get-Content secrets\database_url.txt)'" -ForegroundColor White
Write-Host "  uvicorn dpp_api.main:app --host localhost --port 8000 --reload" -ForegroundColor White
Write-Host ""

Write-Host "🌐 Terminal 2 - Start Portal:" -ForegroundColor Magenta
Write-Host "  cd portal" -ForegroundColor White
Write-Host "  npm install" -ForegroundColor White
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  API:    http://localhost:8000" -ForegroundColor White
Write-Host "  Docs:   http://localhost:8000/docs" -ForegroundColor White
Write-Host "  Portal: http://localhost:3000" -ForegroundColor White
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "📖 For detailed instructions, see LOCAL_DEV.md" -ForegroundColor Yellow
Write-Host ""

# Ask if user wants to view logs
Write-Host "View PostgreSQL logs? (y/n): " -ForegroundColor Yellow -NoNewline
$viewLogs = Read-Host
if ($viewLogs -eq 'y' -or $viewLogs -eq 'Y') {
    docker compose -f compose.local-dev.yaml logs -f postgres
}
