# Stop Local Development Environment
# This script stops PostgreSQL and provides instructions for stopping API and Portal

param(
    [switch]$RemoveVolumes,
    [switch]$Force
)

Write-Host "🛑 Stopping Local Development Environment" -ForegroundColor Cyan
Write-Host ""

# Stop PostgreSQL
Write-Host "Stopping PostgreSQL..." -ForegroundColor Yellow

if ($RemoveVolumes -or $Force) {
    Write-Host "Removing volumes..." -ForegroundColor Yellow
    docker compose -f compose.local-dev.yaml down -v
    Write-Host "✓ PostgreSQL stopped and volumes removed" -ForegroundColor Green
} else {
    docker compose -f compose.local-dev.yaml down
    Write-Host "✓ PostgreSQL stopped" -ForegroundColor Green
}

Write-Host ""

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Remember to stop API and Portal:" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C in the API terminal" -ForegroundColor White
Write-Host "Press Ctrl+C in the Portal terminal" -ForegroundColor White
Write-Host ""

# Ask if user wants to remove volumes (only if not already specified)
if (-not $RemoveVolumes -and -not $Force) {
    Write-Host "Remove PostgreSQL data volumes? (y/n): " -ForegroundColor Yellow -NoNewline
    $removeVolumes = Read-Host
    if ($removeVolumes -eq 'y' -or $removeVolumes -eq 'Y') {
        Write-Host "Removing volumes..." -ForegroundColor Yellow
        docker compose -f compose.local-dev.yaml down -v
        Write-Host "✓ Volumes removed (database will be reseeded on next start)" -ForegroundColor Green
    }
}
