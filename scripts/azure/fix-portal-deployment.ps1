#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix Azure App Service configuration for Next.js portal
.DESCRIPTION
    Sets the correct app settings and startup command to ensure node_modules are available at runtime
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "dpp-brickquack",
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "dpp-brickquack"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "🔧 Fixing Azure App Service Configuration for Portal" -ForegroundColor Cyan
Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor Gray
Write-Host "   App Name: $AppName" -ForegroundColor Gray
Write-Host ""

# Check Azure login
Write-Host "🔐 Checking Azure login..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host ""

# Configure App Settings
Write-Host "⚙️  Configuring App Settings..." -ForegroundColor Cyan
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --settings `
        "SCM_DO_BUILD_DURING_DEPLOYMENT=true" `
        "WEBSITE_NODE_DEFAULT_VERSION=~20" `
        "NODE_ENV=production" `
        "NPM_CONFIG_PRODUCTION=false" `
        "WEBSITE_RUN_FROM_PACKAGE=0" `
        "ENABLE_ORYX_BUILD=true" `
        "POST_BUILD_COMMAND=echo 'Build complete. Verifying...' && ls -la node_modules/next && echo 'Next.js found!'" `
        "API_BASE=https://dpp-brickquack-api.azurewebsites.net" `
    --output table

Write-Host "✅ App settings configured" -ForegroundColor Green
Write-Host ""

# Set startup command
Write-Host "⚙️  Setting startup command..." -ForegroundColor Cyan
az webapp config set `
    --resource-group $ResourceGroup `
    --name $AppName `
    --startup-file "bash startup.sh" `
    --output none

Write-Host "✅ Startup command set to: bash startup.sh" -ForegroundColor Green
Write-Host ""

# Restart the app to apply settings
Write-Host "🔄 Restarting App Service..." -ForegroundColor Cyan
az webapp restart --resource-group $ResourceGroup --name $AppName --output none
Write-Host "✅ App Service restarted" -ForegroundColor Green
Write-Host ""

Write-Host "✅ Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Right-click the 'portal' folder in VS Code" -ForegroundColor Gray
Write-Host "   2. Select 'Deploy to Web App...'" -ForegroundColor Gray
Write-Host "   3. Choose: $AppName" -ForegroundColor Gray
Write-Host "   4. Wait 3-5 minutes for deployment" -ForegroundColor Gray
Write-Host ""
Write-Host "📊 Monitor deployment with:" -ForegroundColor Cyan
Write-Host "   az webapp log tail --name $AppName --resource-group $ResourceGroup" -ForegroundColor Gray
Write-Host ""

