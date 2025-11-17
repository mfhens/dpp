#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Configure Azure App Service for Next.js Portal
.DESCRIPTION
    Sets the correct startup command and app settings for the DPP Portal
.PARAMETER ResourceGroup
    The Azure resource group name
.PARAMETER AppName
    The Azure App Service name
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "dpp-brickquack",
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "dpp-brickquack"
)

$ErrorActionPreference = "Stop"

Write-Host "⚙️  Configuring Azure App Service for Next.js Portal" -ForegroundColor Cyan
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

# Configure startup command
Write-Host ""
Write-Host "🔧 Setting startup command..." -ForegroundColor Cyan
az webapp config set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --startup-file "npm start"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Startup command configured" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to set startup command" -ForegroundColor Red
    exit 1
}

# Set Node.js version
Write-Host ""
Write-Host "🔧 Setting Node.js version..." -ForegroundColor Cyan
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --settings "WEBSITE_NODE_DEFAULT_VERSION=20.19.5"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Node.js version set to 20.19.5" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to set Node.js version" -ForegroundColor Red
}

# Enable build automation
Write-Host ""
Write-Host "🔧 Enabling build automation..." -ForegroundColor Cyan
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --settings "SCM_DO_BUILD_DURING_DEPLOYMENT=true"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build automation enabled" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to enable build automation" -ForegroundColor Red
}

# Set production environment
Write-Host ""
Write-Host "🔧 Setting NODE_ENV to production..." -ForegroundColor Cyan
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --settings "NODE_ENV=production"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ NODE_ENV set to production" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to set NODE_ENV" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Deploy the portal using: .\deploy-portal-to-azure.ps1" -ForegroundColor Gray
Write-Host "   2. Monitor logs with: az webapp log tail --name $AppName --resource-group $ResourceGroup" -ForegroundColor Gray
Write-Host ""
