#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run full demo sequence for DPP Brickquack

.DESCRIPTION
    This script demonstrates the full DPP workflow:
    1. Reset database (first time)
    2. Pause for observation
    3. Reset database (second time)
    4. Wait for user confirmation
    5. Upload planning insights data

.EXAMPLE
    .\run-demo.ps1
#>

$ErrorActionPreference = "Stop"

# Color functions
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host $msg -ForegroundColor Red }

# Banner
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║          DPP BRICKQUACK - DEMO SEQUENCE                    ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: First database reset
Write-Info "┌─────────────────────────────────────────────────────────┐"
Write-Info "│ STEP 1: Initial Database Reset                          │"
Write-Info "└─────────────────────────────────────────────────────────┘"
Write-Host ""

try {
    .\reset-demo-database-azure.ps1
    Write-Success "✅ First database reset completed!"
} catch {
    Write-Fail "❌ First reset failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Warn "⏸️  Pausing for 5 seconds to observe the initial state..."
Start-Sleep -Seconds 5

# Step 2: Second database reset
Write-Host ""
Write-Info "┌─────────────────────────────────────────────────────────┐"
Write-Info "│ STEP 2: Second Database Reset                           │"
Write-Info "└─────────────────────────────────────────────────────────┘"
Write-Host ""

try {
    .\reset-demo-database-azure.ps1
    Write-Success "✅ Second database reset completed!"
} catch {
    Write-Fail "❌ Second reset failed: $($_.Exception.Message)"
    exit 1
}

# Step 3: Wait for user input
Write-Host ""
Write-Info "┌─────────────────────────────────────────────────────────┐"
Write-Info "│ STEP 3: Ready to Upload Planning Insights              │"
Write-Info "└─────────────────────────────────────────────────────────┘"
Write-Host ""
Write-Warn "📋 The database has been reset twice and is ready."
Write-Host ""
Write-Host "   Next action will upload planning insights from:" -ForegroundColor Gray
Write-Host "   📄 seed\WKPRODLOCLOCFROM.csv" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to continue with the upload..." -ForegroundColor White -NoNewline
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

# Step 4: Upload planning insights
Write-Host ""
Write-Info "┌─────────────────────────────────────────────────────────┐"
Write-Info "│ STEP 4: Uploading Planning Insights                    │"
Write-Info "└─────────────────────────────────────────────────────────┘"
Write-Host ""

try {
    .\upload-planning-insights-azure.ps1 -CsvFile "seed\WKPRODLOCLOCFROM.csv" -ApiUrl "https://dpp-brickquack-api.azurewebsites.net"
    Write-Success "✅ Planning insights uploaded successfully!"
} catch {
    Write-Fail "❌ Upload failed: $($_.Exception.Message)"
    exit 1
}

# Demo complete
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                            ║" -ForegroundColor Green
Write-Host "║          🎉 DEMO SEQUENCE COMPLETED! 🎉                    ║" -ForegroundColor Green
Write-Host "║                                                            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Info "📊 Summary of actions performed:"
Write-Host "   ✅ Database reset (1st time)" -ForegroundColor Gray
Write-Host "   ✅ Database reset (2nd time)" -ForegroundColor Gray
Write-Host "   ✅ Planning insights uploaded from WKPRODLOCLOCFROM.csv" -ForegroundColor Gray
Write-Host ""
Write-Info "Next steps:"
Write-Host "   • View DPPs in portal: https://dpp-brickquack-api.azurewebsites.net/../dpp" -ForegroundColor Gray
Write-Host "   • Check API health: https://dpp-brickquack-api.azurewebsites.net/health" -ForegroundColor Gray
Write-Host "   • View logs: .\view-logs.ps1" -ForegroundColor Gray
Write-Host ""
