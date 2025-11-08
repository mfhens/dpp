#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Interactive POC Demo Script for Azure deployment

.DESCRIPTION
    This script guides a non-technical user through the complete POC demonstration using Azure-hosted services:
    1. Verifies Azure services are available
    2. Shows how to find and view a DPP (Lego Duck)
    3. Demonstrates uploading planning insights via API
    4. Shows the updated DPP with new planning data

.PARAMETER ApiUrl
    The Azure API base URL

.PARAMETER PortalUrl
    The Azure Portal base URL

.EXAMPLE
    .\demo-poc-azure.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ApiUrl = "https://dpp-brickquack-api.azurewebsites.net",
    
    [Parameter(Mandatory=$false)]
    [string]$PortalUrl = "https://dpp-brickquack.azurewebsites.net"
)

$ErrorActionPreference = "Stop"

function Wait-ForKeyPress {
    param([string]$Message = "Press any key to continue...")
    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
}

function Test-ServiceRunning {
    param([string]$Url, [string]$ServiceName)
    try {
        # Try /health first, then root endpoint as fallback
        try {
            $null = Invoke-WebRequest -Uri "$Url/health" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        } catch {
            $null = Invoke-WebRequest -Uri "$Url/" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        }
        return $true
    } catch {
        return $false
    }
}

# Header
Clear-Host
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     🎯 DPP POC DEMO - AZURE DEPLOYMENT                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "This demo will walk you through:" -ForegroundColor White
Write-Host "  1. Finding and viewing a Digital Product Passport" -ForegroundColor Gray
Write-Host "  2. Uploading planning insights data" -ForegroundColor Gray
Write-Host "  3. Viewing the updated DPP with new information" -ForegroundColor Gray
Write-Host ""
Write-Host "🌐 Azure Services:" -ForegroundColor Cyan
Write-Host "   API:    $ApiUrl" -ForegroundColor Gray
Write-Host "   Portal: $PortalUrl" -ForegroundColor Gray
Write-Host ""

Wait-ForKeyPress "Press any key to start the demo..."

# ============================================================================
# STEP 1: VERIFY ENVIRONMENT
# ============================================================================
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 1: Checking Azure Services                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔍 Checking if services are running..." -ForegroundColor Cyan
Write-Host ""

$apiRunning = Test-ServiceRunning -Url $ApiUrl -ServiceName "API"
$portalRunning = Test-ServiceRunning -Url $PortalUrl -ServiceName "Portal"

if ($apiRunning) {
    Write-Host "   ✅ API is running on $ApiUrl" -ForegroundColor Green
} else {
    Write-Host "   ❌ API is NOT responding at $ApiUrl" -ForegroundColor Red
}

if ($portalRunning) {
    Write-Host "   ✅ Portal is running on $PortalUrl" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Portal is NOT responding at $PortalUrl" -ForegroundColor Yellow
}

Write-Host ""

if (-not $apiRunning) {
    Write-Host "⚠️  The API is not responding!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor White
    Write-Host "   • Is the API deployed to Azure?" -ForegroundColor Gray
    Write-Host "   • Try opening $ApiUrl in your browser" -ForegroundColor Gray
    Write-Host "   • Check status: az webapp show --name dpp-brickquack-api --resource-group dpp-brickquack --query state" -ForegroundColor Gray
    Write-Host "   • View logs: az webapp log tail --name dpp-brickquack-api --resource-group dpp-brickquack" -ForegroundColor Gray
    Write-Host ""
    
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
}

Write-Host "✅ Environment check complete!" -ForegroundColor Green

Wait-ForKeyPress

# ============================================================================
# STEP 2: VIEW LEGO DUCK DPP (BEFORE)
# ============================================================================
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 2: Finding the Lego Duck DPP                      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "📦 We'll look at the Lego Duck product passport" -ForegroundColor White
Write-Host "   This shows all product information including:" -ForegroundColor Gray
Write-Host "   • Materials and components" -ForegroundColor Gray
Write-Host "   • Environmental footprint" -ForegroundColor Gray
Write-Host "   • Compliance certificates" -ForegroundColor Gray
Write-Host "   • Current planning insights (if any)" -ForegroundColor Gray
Write-Host ""

$legoDuckId = "did:web:dpp-brickquack.azurewebsites.net:product:lego-duck:item-sn-2025-ld-001234"

Write-Host "🔍 Fetching DPP from Azure..." -ForegroundColor Cyan
Write-Host "   ID: $legoDuckId" -ForegroundColor Gray
Write-Host ""

try {
    $beforeResponse = Invoke-RestMethod -Uri "$ApiUrl/dpp/$legoDuckId" -Method Get -TimeoutSec 30
    
    Write-Host "✅ DPP Retrieved!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Product Information:" -ForegroundColor Cyan
    Write-Host "   Model: $($beforeResponse.product.model)" -ForegroundColor White
    Write-Host "   Description: $($beforeResponse.product.description)" -ForegroundColor White
    Write-Host "   Category: $($beforeResponse.product.category)" -ForegroundColor White
    Write-Host "   Serial: $($beforeResponse.product.serialNumber)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🌍 Environmental Footprint:" -ForegroundColor Cyan
    Write-Host "   Carbon: $($beforeResponse.environmentalFootprint.productCarbonFootprint.value) $($beforeResponse.environmentalFootprint.productCarbonFootprint.unit)" -ForegroundColor White
    Write-Host "   Water: $($beforeResponse.environmentalFootprint.waterFootprint) L" -ForegroundColor White
    Write-Host "   Energy: $($beforeResponse.environmentalFootprint.energyConsumption) kWh" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📊 Planning Insights (BEFORE):" -ForegroundColor Cyan
    if ($beforeResponse.planningInsights -and $beforeResponse.planningInsights.PSObject.Properties.Count -gt 0) {
        Write-Host "   Some data exists" -ForegroundColor Gray
        $beforeResponse.planningInsights | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Gray
    } else {
        Write-Host "   ⚠️  No planning insights yet" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "❌ Failed to retrieve DPP: $_"
    Write-Host ""
    Write-Host "This might mean:" -ForegroundColor Yellow
    Write-Host "   • The database hasn't been seeded yet" -ForegroundColor Gray
    Write-Host "   • Run: .\reset-demo-database-azure.ps1" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "💡 You can also view this in your browser:" -ForegroundColor Cyan
Write-Host "   $PortalUrl/dpp/$legoDuckId" -ForegroundColor White

Wait-ForKeyPress

# ============================================================================
# STEP 3: UPLOAD PLANNING INSIGHTS (MANUAL)
# ============================================================================
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 3: Upload Planning Insights via Portal            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "📤 Manual Upload Instructions:" -ForegroundColor White
Write-Host ""
Write-Host "   To upload planning insights CSV data:" -ForegroundColor Gray
Write-Host ""
Write-Host "   1️⃣  Open the Portal in your browser:" -ForegroundColor Cyan
Write-Host "      $PortalUrl/upload" -ForegroundColor White
Write-Host ""
Write-Host "   2️⃣  Navigate to the Upload page" -ForegroundColor Cyan
Write-Host ""
Write-Host "   3️⃣  Upload the CSV file:" -ForegroundColor Cyan
Write-Host "      📂 $((Get-Item 'seed\SSCP1__PRODLOCLOCFR_DEMO.csv').FullName)" -ForegroundColor White
Write-Host ""
Write-Host "   4️⃣  The CSV contains planning insights for:" -ForegroundColor Cyan
Write-Host "      • LEGO-DUCK (2 locations)" -ForegroundColor Gray
Write-Host "      • RED-PLATE-BRICK (3 locations)" -ForegroundColor Gray
Write-Host "      • YELLOW-PLATE-BRICK (3 locations)" -ForegroundColor Gray
Write-Host "      • DUCK-EYE (2 locations)" -ForegroundColor Gray
Write-Host ""
Write-Host "   5️⃣  After upload, the DPPs will have updated:" -ForegroundColor Cyan
Write-Host "      • Transport optimization data" -ForegroundColor Gray
Write-Host "      • Carbon footprint reductions" -ForegroundColor Gray
Write-Host "      • Location-specific logistics" -ForegroundColor Gray
Write-Host ""

$csvPath = "seed\SSCP1__PRODLOCLOCFR_DEMO.csv"
if (Test-Path $csvPath) {
    Write-Host "📊 CSV Preview (first 3 rows):" -ForegroundColor Cyan
    Get-Content $csvPath -TotalCount 3 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    Write-Host "   ... (10 total records)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "💡 TIP: You can also use the API directly:" -ForegroundColor Yellow
Write-Host "   POST $ApiUrl/dpp/{dpp_id}/versions" -ForegroundColor Gray
Write-Host "   with updated payload including planningInsights" -ForegroundColor Gray
Write-Host ""

Wait-ForKeyPress "Press any key to continue (after you've uploaded via Portal)..."

# ============================================================================
# STEP 4: VIEW DPP (can show with or without planning insights)
# ============================================================================
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 4: Viewing the Lego Duck DPP                      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔍 Fetching current DPP from Azure..." -ForegroundColor Cyan
Write-Host ""

try {
    $afterResponse = Invoke-RestMethod -Uri "$ApiUrl/dpp/$legoDuckId" -Method Get -TimeoutSec 30
    
    Write-Host "✅ DPP Retrieved!" -ForegroundColor Green
    Write-Host ""
    
    $payload = $afterResponse.payload
    
    # Check if planning insights exist
    if ($payload.planningInsights -and $payload.planningInsights.PSObject.Properties.Count -gt 0) {
        Write-Host "📊 Planning Insights Status: ✅ UPDATED" -ForegroundColor Green
        Write-Host ""
        
        # Show summary insights from seed data
        if ($payload.planningInsights.demandForecast) {
            Write-Host "   � Demand Forecast:" -ForegroundColor Cyan
            Write-Host "      $($payload.planningInsights.demandForecast)" -ForegroundColor White
        }
        
        if ($payload.planningInsights.supplyChainOptimization) {
            Write-Host ""
            Write-Host "   🚚 Supply Chain:" -ForegroundColor Cyan
            Write-Host "      $($payload.planningInsights.supplyChainOptimization)" -ForegroundColor White
        }
        
        if ($payload.planningInsights.maintenanceSchedule) {
            Write-Host ""
            Write-Host "   � Maintenance:" -ForegroundColor Cyan
            Write-Host "      $($payload.planningInsights.maintenanceSchedule)" -ForegroundColor White
        }
        
        # If uploaded via CSV, show location-specific data
        if ($payload.planningInsights.locations) {
            Write-Host ""
            Write-Host "   📍 Location-Specific Insights:" -ForegroundColor Cyan
            Write-Host "      Showing first 2 locations..." -ForegroundColor Gray
            $payload.planningInsights.locations | Select-Object -First 2 | ForEach-Object {
                Write-Host ""
                Write-Host "      • $($_.locationId)" -ForegroundColor White
                Write-Host "        Transport: $($_.adjustedTransportQuantity) units" -ForegroundColor Gray
                Write-Host "        Footprint: $($_.currentTransportFootprint) kg CO2e" -ForegroundColor Gray
            }
        }
        
    } else {
        Write-Host "📊 Planning Insights Status: ⚠️  NOT YET UPLOADED" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   The DPP currently has baseline planning insights." -ForegroundColor Gray
        Write-Host "   Upload the CSV via Portal to add location-specific data." -ForegroundColor Gray
    }
    
} catch {
    Write-Error "❌ Failed to retrieve DPP: $_"
    exit 1
}

Write-Host ""

Wait-ForKeyPress

# ============================================================================
# SUMMARY
# ============================================================================
Clear-Host
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           ✅ DEMO COMPLETE                              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "🎉 You have successfully:" -ForegroundColor Cyan
Write-Host "   ✅ Verified Azure services are running" -ForegroundColor Green
Write-Host "   ✅ Retrieved a Digital Product Passport from Azure" -ForegroundColor Green
Write-Host "   ✅ Learned how to upload planning insights via Portal" -ForegroundColor Green
Write-Host ""

Write-Host "🔗 Azure Services:" -ForegroundColor Cyan
Write-Host "   • API:      $ApiUrl" -ForegroundColor White
Write-Host "   • Portal:   $PortalUrl" -ForegroundColor White
Write-Host "   • API Docs: $ApiUrl/docs" -ForegroundColor White
Write-Host ""

Write-Host "📚 More Examples:" -ForegroundColor Cyan
Write-Host "   # View raw material (ABS from Thailand)" -ForegroundColor Gray
Write-Host "   Invoke-RestMethod -Uri '$ApiUrl/dpp/did:web:dpp-brickquack.azurewebsites.net:raw:abs01:batch-2025-10-001'" -ForegroundColor White
Write-Host ""
Write-Host "   # View component (Red Brick)" -ForegroundColor Gray
Write-Host "   Invoke-RestMethod -Uri '$ApiUrl/dpp/did:web:dpp-brickquack.azurewebsites.net:component:red-plate-brick:batch-2025-Q4-001'" -ForegroundColor White
Write-Host ""

Write-Host "🔄 To Reset Demo:" -ForegroundColor Cyan
Write-Host "   .\reset-demo-database-azure.ps1" -ForegroundColor White
Write-Host ""

Write-Host "📖 For detailed guide, see: docs\POC-DEMO-GUIDE-AZURE.md" -ForegroundColor Cyan
Write-Host ""
