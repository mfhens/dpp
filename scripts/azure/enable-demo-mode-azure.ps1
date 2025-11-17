#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Enable DEMO_MODE for Azure API to allow anonymous uploads
.DESCRIPTION
    Sets DEMO_MODE=1 in Azure App Service app settings
.PARAMETER ResourceGroup
    The Azure resource group name
.PARAMETER AppName
    The Azure App Service name for the API
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "dpp-brickquack",
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "dpp-brickquack-api"
)

$ErrorActionPreference = "Stop"

Write-Host "🎯 Enabling DEMO_MODE for DPP API" -ForegroundColor Cyan
Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor Gray
Write-Host "   App Name: $AppName" -ForegroundColor Gray
Write-Host ""

# Check if logged in to Azure
Write-Host "🔐 Checking Azure login..." -ForegroundColor Cyan
$account = az account show 2>$null
if (-not $account) {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Logged in to Azure" -ForegroundColor Green

# Verify app exists
Write-Host "🔍 Verifying App Service exists..." -ForegroundColor Cyan
$app = az webapp show --name $AppName --resource-group $ResourceGroup 2>$null
if (-not $app) {
    Write-Host "❌ App Service '$AppName' not found in resource group '$ResourceGroup'" -ForegroundColor Red
    exit 1
}
Write-Host "✅ App Service found" -ForegroundColor Green

# Enable DEMO_MODE
Write-Host ""
Write-Host "🔧 Setting DEMO_MODE=1..." -ForegroundColor Cyan
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --settings "DEMO_MODE=1"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ DEMO_MODE enabled" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  IMPORTANT:" -ForegroundColor Yellow
    Write-Host "   DEMO_MODE allows anonymous POST/PUT/DELETE requests" -ForegroundColor Yellow
    Write-Host "   This is intended for demo/POC purposes only" -ForegroundColor Yellow
    Write-Host "   Do NOT use in production with real data" -ForegroundColor Yellow
} else {
    Write-Host "❌ Failed to set DEMO_MODE" -ForegroundColor Red
    exit 1
}

# Restart the app to apply changes
Write-Host ""
Write-Host "🔄 Restarting App Service to apply changes..." -ForegroundColor Cyan
az webapp restart --name $AppName --resource-group $ResourceGroup

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ App Service restarted" -ForegroundColor Green
} else {
    Write-Host "⚠️  Failed to restart App Service" -ForegroundColor Yellow
    Write-Host "   You may need to restart it manually" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Your API is now in DEMO_MODE" -ForegroundColor Cyan
Write-Host "   Test the upload endpoint at:" -ForegroundColor Gray
Write-Host "   https://$AppName.azurewebsites.net/upload/planning-insights" -ForegroundColor White
Write-Host ""
Write-Host "📝 To disable DEMO_MODE later:" -ForegroundColor Cyan
Write-Host "   az webapp config appsettings set --resource-group $ResourceGroup --name $AppName --settings DEMO_MODE=0" -ForegroundColor Gray
Write-Host ""
