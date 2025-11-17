#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Upload planning insights CSV to Azure DPP API

.DESCRIPTION
    Uploads a planning insights CSV file to the Azure-hosted DPP API.
    Works with the /upload/planning-insights endpoint in DEMO_MODE.

.PARAMETER CsvFile
    Path to the CSV file to upload (default: seed\SSCP1__PRODLOCLOCFR_DEMO.csv)

.PARAMETER ApiUrl
    The Azure API base URL (default: https://dpp-brickquack-api.azurewebsites.net)

.EXAMPLE
    .\upload-planning-insights-azure.ps1

.EXAMPLE
    .\upload-planning-insights-azure.ps1 -CsvFile "my-data.csv" -ApiUrl "https://my-api.azurewebsites.net"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$CsvFile = "seed\SSCP1__PRODLOCLOCFR_DEMO.csv",
    
    [Parameter(Mandatory=$false)]
    [string]$ApiUrl = "https://dpp-brickquack-api.azurewebsites.net"
)

$ErrorActionPreference = "Stop"

# Color functions
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host $msg -ForegroundColor Red }

Write-Info "📤 Planning Insights CSV Upload"
Write-Info "================================"
Write-Host ""

# Validate CSV file exists
if (-not (Test-Path $CsvFile)) {
    Write-Fail "❌ CSV file not found: $CsvFile"
    exit 1
}

$csvPath = Resolve-Path $CsvFile
$fileName = Split-Path $csvPath -Leaf
$fileSize = (Get-Item $csvPath).Length

Write-Info "📋 Upload Details:"
Write-Host "   File: $fileName" -ForegroundColor Gray
Write-Host "   Size: $([math]::Round($fileSize/1KB, 2)) KB" -ForegroundColor Gray
Write-Host "   API:  $ApiUrl" -ForegroundColor Gray
Write-Host ""

# Check if API is reachable
Write-Info "🔍 Checking API connectivity..."
try {
    $healthCheck = Invoke-RestMethod -Uri "$ApiUrl/health" -Method Get -ErrorAction Stop
    Write-Success "   ✅ API is reachable (status: $($healthCheck.status))"
} catch {
    Write-Warn "   ⚠️  Could not reach health endpoint, but will try upload anyway..."
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
}
Write-Host ""

# Prepare multipart form data
Write-Info "📦 Preparing upload..."

# Read file content
$fileBytes = [System.IO.File]::ReadAllBytes($csvPath)
$fileEnc = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes)

# Create boundary for multipart/form-data
$boundary = [System.Guid]::NewGuid().ToString()

# Build multipart body
$LF = "`r`n"
$bodyLines = (
    "--$boundary",
    "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
    "Content-Type: text/csv$LF",
    $fileEnc,
    "--$boundary--$LF"
) -join $LF

# Upload the file
Write-Info "🚀 Uploading to $ApiUrl/upload/planning-insights..."

try {
    $response = Invoke-RestMethod `
        -Uri "$ApiUrl/upload/planning-insights" `
        -Method Post `
        -ContentType "multipart/form-data; boundary=$boundary" `
        -Body $bodyLines `
        -ErrorAction Stop
    
    Write-Host ""
    Write-Success "✅ Upload successful!"
    Write-Host ""
    Write-Info "📊 Results:"
    Write-Host "   Records read:      $($response.records_read)" -ForegroundColor White
    Write-Host "   DPPs updated:      $($response.dpps_updated)" -ForegroundColor Green
    Write-Host "   DPPs not found:    $($response.dpps_not_found)" -ForegroundColor $(if ($response.dpps_not_found -gt 0) { 'Yellow' } else { 'Gray' })
    Write-Host ""
    
    if ($response.dpps_not_found -gt 0) {
        Write-Warn "⚠️  Some DPPs were not found in the database."
        Write-Host "   Make sure to seed the database first with:" -ForegroundColor Gray
        Write-Host "   .\reset-demo-database-azure.ps1" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Success "🎉 Planning insights data has been applied to the DPPs!"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "   • View updated DPPs in the portal: $ApiUrl/../dpp" -ForegroundColor Gray
    Write-Host "   • Check specific DPP: $ApiUrl/dpp/{dpp-id}" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Fail "❌ Upload failed!"
    Write-Host ""
    Write-Host "Error details:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.ErrorDetails) {
        Write-Host ""
        Write-Host "API Response:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Info "Troubleshooting:"
    Write-Host "   • Check if API is running: $ApiUrl/health" -ForegroundColor Gray
    Write-Host "   • Verify DEMO_MODE is enabled in Azure App Service settings" -ForegroundColor Gray
    Write-Host "   • Check API logs: az webapp log tail --name dpp-brickquack-api --resource-group dpp-brickquack" -ForegroundColor Gray
    Write-Host ""
    
    exit 1
}
