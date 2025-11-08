#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Reset Azure database to demo-ready state with Lego Duck sample data

.DESCRIPTION
    This script prepares the Azure-hosted database for a demo by:
    1. Clearing all existing data via API
    2. Reseeding with the Lego Duck sample data
    3. Verifying the data is ready for demo

    Perfect for ensuring a consistent starting point before each demo.

.PARAMETER ApiUrl
    The Azure API base URL (default: https://dpp-brickquack-api.azurewebsites.net)

.EXAMPLE
    .\reset-demo-database-azure.ps1
    
.EXAMPLE
    .\reset-demo-database-azure.ps1 -ApiUrl "https://your-api.azurewebsites.net"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ApiUrl = "https://dpp-brickquack-api.azurewebsites.net"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     🔄 RESET AZURE DATABASE TO DEMO STATE              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "   API: $ApiUrl" -ForegroundColor Gray
Write-Host ""

# Check if running from project root
if (-not (Test-Path "seed/postgres/lego-duck-sample-dpps.ndjson")) {
    Write-Error "❌ Please run this script from the project root directory"
    exit 1
}

Write-Host "📋 This will:" -ForegroundColor Yellow
Write-Host "   • Delete all existing DPPs from Azure database" -ForegroundColor Gray
Write-Host "   • Load Lego Duck sample data (9 products)" -ForegroundColor Gray
Write-Host "   • Verify data is ready for demo" -ForegroundColor Gray
Write-Host ""

# Prompt for confirmation
$confirmation = Read-Host "Continue? (y/N)"
if ($confirmation -ne "y" -and $confirmation -ne "Y") {
    Write-Host "❌ Cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🔍 Step 1: Checking API availability..." -ForegroundColor Cyan

try {
    # Try /health first (newer API), then root endpoint
    try {
        $null = Invoke-RestMethod -Uri "$ApiUrl/health" -Method Get -TimeoutSec 10
    } catch {
        # Fallback to root endpoint
        $null = Invoke-RestMethod -Uri "$ApiUrl/" -Method Get -TimeoutSec 10
    }
    Write-Host "   ✅ API is responding" -ForegroundColor Green
} catch {
    Write-Host "   ❌ API is not responding at $ApiUrl" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Please check:" -ForegroundColor Yellow
    Write-Host "   • Is the API deployed and running?" -ForegroundColor Gray
    Write-Host "   • Try opening $ApiUrl in your browser" -ForegroundColor Gray
    Write-Host "   • Check logs: az webapp log tail --name dpp-brickquack-api --resource-group dpp-brickquack" -ForegroundColor Gray
    Write-Host "   • Check status: az webapp show --name dpp-brickquack-api --resource-group dpp-brickquack --query state" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "🗑️  Step 2: Clearing existing data..." -ForegroundColor Cyan

# Get all existing DPPs
try {
    $existingDpps = Invoke-RestMethod -Uri "$ApiUrl/dpp" -Method Get -TimeoutSec 30
    
    if ($existingDpps -and $existingDpps.Count -gt 0) {
        Write-Host "   Found $($existingDpps.Count) existing DPPs" -ForegroundColor Gray
        
        $deletedCount = 0
        foreach ($dpp in $existingDpps) {
            try {
                Invoke-RestMethod -Uri "$ApiUrl/dpp/$($dpp.id)" -Method Delete -TimeoutSec 10 | Out-Null
                $deletedCount++
                Write-Host "   ✅ Deleted: $($dpp.product_id)" -ForegroundColor Green
            } catch {
                Write-Host "   ⚠️  Failed to delete: $($dpp.product_id)" -ForegroundColor Yellow
            }
        }
        
        Write-Host "   ✅ Deleted $deletedCount DPPs" -ForegroundColor Green
    } else {
        Write-Host "   ℹ️  No existing data found" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ⚠️  Could not retrieve existing DPPs (may not exist)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🌱 Step 3: Seeding database with Lego Duck data..." -ForegroundColor Cyan

# Read the NDJSON file
$ndjsonPath = "seed/postgres/lego-duck-sample-dpps.ndjson"
$lines = Get-Content $ndjsonPath

Write-Host "   Found $($lines.Count) records to upload" -ForegroundColor Gray
Write-Host ""

$uploadedCount = 0
$failedCount = 0

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }
    
    try {
        $dpp = $line | ConvertFrom-Json
        $productId = $dpp.product.model ?? $dpp.product.serialNumber ?? $dpp.id
        
        Write-Host "   Uploading: $productId..." -ForegroundColor Gray
        
        # Transform to API format: { product_id, model, batch?, payload }
        $apiRequest = @{
            product_id = $productId
            model = $dpp.product.model ?? "unknown"
            batch = $dpp.product.batchOrLot
            payload = $dpp
        }
        
        $body = $apiRequest | ConvertTo-Json -Depth 20 -Compress
        $null = Invoke-RestMethod `
            -Uri "$ApiUrl/dpp" `
            -Method Post `
            -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 30
        
        Write-Host "   ✅ $productId" -ForegroundColor Green
        $uploadedCount++
        
    } catch {
        Write-Host "   ❌ Failed: $productId" -ForegroundColor Red
        Write-Host "      Error: $_" -ForegroundColor Red
        $failedCount++
    }
}

Write-Host ""
if ($uploadedCount -gt 0) {
    Write-Host "✅ Step 4: Verifying data..." -ForegroundColor Cyan
    
    # Verify Lego Duck exists
    $legoDuckId = "did:web:dpp.brickquack.com:product:lego-duck:item-SN-2025-LD-001234"
    
    try {
        $legoDuck = Invoke-RestMethod -Uri "$ApiUrl/dpp/$legoDuckId" -Method Get -TimeoutSec 10
        Write-Host "   ✅ Lego Duck found: $($legoDuck.product.model)" -ForegroundColor Green
        Write-Host "   ✅ Version: $($legoDuck.schemaVersion)" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Could not verify Lego Duck" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║     ✅ DATABASE RESET COMPLETE                          ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Results:" -ForegroundColor Cyan
    Write-Host "   Uploaded: $uploadedCount records" -ForegroundColor White
    if ($failedCount -gt 0) {
        Write-Host "   Failed: $failedCount records" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "📦 Sample Data Available:" -ForegroundColor Cyan
    Write-Host "   • 5 Raw Materials (ABS, Carbon Black, Packaging)" -ForegroundColor White
    Write-Host "   • 3 Components (Red Brick, Yellow Brick, Duck Eye)" -ForegroundColor White
    Write-Host "   • 1 Finished Product (Lego Duck)" -ForegroundColor White
    Write-Host ""
    Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Run demo: .\demo-poc-azure.ps1" -ForegroundColor White
    Write-Host "   2. Open Portal: https://dpp-brickquack.azurewebsites.net" -ForegroundColor White
    Write-Host "   3. API Docs: $ApiUrl/docs" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ RESET FAILED" -ForegroundColor Red
    Write-Host "   No records were uploaded successfully" -ForegroundColor Yellow
    Write-Host "   Please check the API logs and try again" -ForegroundColor Yellow
    exit 1
}
