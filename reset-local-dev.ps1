# Reset Local Development Database
# This script completely removes PostgreSQL data and restarts with a fresh database

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║               RESET PostgreSQL Database                       ║" -ForegroundColor Red
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "⚠️  WARNING: This will delete ALL PostgreSQL data!" -ForegroundColor Yellow
Write-Host ""
Write-Host "This is useful when:" -ForegroundColor Gray
Write-Host "  • Upgrading PostgreSQL versions" -ForegroundColor Gray
Write-Host "  • Database is corrupted" -ForegroundColor Gray
Write-Host "  • You want a fresh start with seed data" -ForegroundColor Gray
Write-Host ""

# Confirm with user
Write-Host "Are you sure you want to continue? (yes/no): " -ForegroundColor Yellow -NoNewline
$confirmation = Read-Host

if ($confirmation -ne "yes") {
    Write-Host "❌ Reset cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🗑️  Stopping and removing PostgreSQL container and volumes..." -ForegroundColor Yellow

# Stop and remove everything related to local-dev compose
docker compose -f compose.local-dev.yaml down -v

# Also try to remove the volume directly in case it's orphaned
Write-Host "🗑️  Removing any orphaned volumes..." -ForegroundColor Yellow
docker volume rm dpp_pgdata -f 2>$null

Write-Host "✓ PostgreSQL data removed" -ForegroundColor Green
Write-Host ""

# Ask if user wants to start fresh
Write-Host "Start PostgreSQL with fresh database? (y/n): " -ForegroundColor Yellow -NoNewline
$startFresh = Read-Host

if ($startFresh -eq 'y' -or $startFresh -eq 'Y') {
    Write-Host ""
    Write-Host "🚀 Starting fresh PostgreSQL instance..." -ForegroundColor Cyan
    docker compose -f compose.local-dev.yaml up -d
    
    # Wait for healthy
    Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
    $maxAttempts = 30
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        try {
            $health = docker compose -f compose.local-dev.yaml ps --format json | ConvertFrom-Json | Where-Object { $_.Service -eq "postgres" } | Select-Object -ExpandProperty Health
            if ($health -eq "healthy") {
                Write-Host "✓ PostgreSQL is ready with fresh database!" -ForegroundColor Green
                break
            }
        } catch {
            # Ignore errors during health check
        }
        $attempt++
        Start-Sleep -Seconds 2
        Write-Host "  Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
    }
    
    if ($attempt -eq $maxAttempts) {
        Write-Host "⚠️  PostgreSQL may not be fully ready. Check logs:" -ForegroundColor Yellow
        Write-Host "  docker compose -f compose.local-dev.yaml logs postgres" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Fresh database is ready!" -ForegroundColor Green
    Write-Host "Seed data has been automatically loaded." -ForegroundColor Gray
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "To start PostgreSQL later, run:" -ForegroundColor Yellow
    Write-Host "  .\start-local-dev.ps1" -ForegroundColor White
}

Write-Host ""
