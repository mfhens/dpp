# Complete Local Development Setup
# This script sets up everything needed for local development:
# 1. Secrets
# 2. PostgreSQL (Docker)
# 3. API environment
# 4. Portal environment

param(
    [switch]$SkipSecrets,
    [switch]$SkipPostgres,
    [switch]$SkipAPI,
    [switch]$SkipPortal
)

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         DPP Local Development - Complete Setup                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

# Step 1: Setup Secrets
if (-not $SkipSecrets) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
    Write-Host "Step 1: Setting up secrets..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
    
    if (-not (Test-Path "secrets\postgres_user.txt")) {
        .\setup-secrets.ps1
        .\verify-secrets.ps1
    } else {
        Write-Host "✓ Secrets already exist" -ForegroundColor Green
    }
} else {
    Write-Host "⊘ Skipping secrets setup" -ForegroundColor Gray
}

# Step 2: Start PostgreSQL
if (-not $SkipPostgres) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
    Write-Host "Step 2: Starting PostgreSQL..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
    
    # Check if already running
    $running = docker compose -f compose.local-dev.yaml ps --format json | ConvertFrom-Json | Where-Object { $_.Service -eq "postgres" -and $_.State -eq "running" }
    
    if ($running) {
        Write-Host "✓ PostgreSQL is already running" -ForegroundColor Green
    } else {
        docker compose -f compose.local-dev.yaml up -d
        
        # Wait for healthy
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
        }
        
        if ($attempt -eq $maxAttempts) {
            Write-Host "✗ PostgreSQL failed to become healthy" -ForegroundColor Red
            exit 1
        }
    }
} else {
    Write-Host "⊘ Skipping PostgreSQL setup" -ForegroundColor Gray
}

# Step 3: Setup API
if (-not $SkipAPI) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
    Write-Host "Step 3: Setting up API..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
    
    .\setup-api.ps1
} else {
    Write-Host "⊘ Skipping API setup" -ForegroundColor Gray
}

# Step 4: Setup Portal
if (-not $SkipPortal) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
    Write-Host "Step 4: Setting up Portal..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
    
    .\setup-portal.ps1
} else {
    Write-Host "⊘ Skipping Portal setup" -ForegroundColor Gray
}

# Summary
$duration = (Get-Date) - $startTime
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    Setup Complete! ✓                           ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Setup completed in $($duration.TotalSeconds.ToString('0.0')) seconds" -ForegroundColor Gray
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "📘 Terminal 1 - Run API:" -ForegroundColor Blue
Write-Host "  cd api" -ForegroundColor White
Write-Host "  .\run.ps1" -ForegroundColor White
Write-Host ""

Write-Host "🌐 Terminal 2 - Run Portal:" -ForegroundColor Magenta
Write-Host "  cd portal" -ForegroundColor White
Write-Host "  .\run.ps1" -ForegroundColor White
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  API:    http://localhost:8000" -ForegroundColor White
Write-Host "  Docs:   http://localhost:8000/docs" -ForegroundColor White
Write-Host "  Portal: http://localhost:3000" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "📖 For more details, see LOCAL_DEV.md" -ForegroundColor Yellow
Write-Host ""
