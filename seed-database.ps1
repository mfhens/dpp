#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Seed the DPP database with Lego Duck sample data

.DESCRIPTION
    Seeds the database with sample DPP records from the Lego Duck example.
    Works with both SQLite (local dev) and PostgreSQL (Docker).

.PARAMETER Force
    Force re-seed even if data already exists

.EXAMPLE
    .\seed-database.ps1
    
.EXAMPLE
    .\seed-database.ps1 -Force
#>

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "🌱 Seeding DPP Database" -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan

# Check if running from project root
if (-not (Test-Path "api/pyproject.toml")) {
    Write-Error "Please run this script from the project root directory"
    exit 1
}

# Change to API directory
Push-Location api

try {
    # Run the seed script
    if ($Force) {
        python -m dpp_api.seed_data --force
    } else {
        python -m dpp_api.seed_data
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Seeding failed"
        exit 1
    }
    
    Write-Host "`n✅ Database seeded successfully!" -ForegroundColor Green
    Write-Host "`n💡 Sample DPPs you can query:" -ForegroundColor Cyan
    Write-Host "   • Finished Product (Lego Duck):" -ForegroundColor Gray
    Write-Host "     curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:product:lego-duck:item-SN-2025-LD-001234" -ForegroundColor White
    Write-Host ""
    Write-Host "   • Component (Red Brick):" -ForegroundColor Gray
    Write-Host "     curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:component:red-plate-brick:batch-2025-Q4-001" -ForegroundColor White
    Write-Host ""
    Write-Host "   • Raw Material (ABS from Thailand):" -ForegroundColor Gray
    Write-Host "     curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:raw:abs01:batch-2025-10-001" -ForegroundColor White
    Write-Host ""
    
} finally {
    Pop-Location
}
