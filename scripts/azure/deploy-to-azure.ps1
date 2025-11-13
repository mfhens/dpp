#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy DPP API to Azure App Service
.DESCRIPTION
    Deploys the API to the specified Azure App Service using ZIP deployment
.PARAMETER ResourceGroup
    The Azure resource group name
.PARAMETER AppName
    The Azure App Service name
.PARAMETER BuildFirst
    Whether to build/prepare the deployment package first
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "dpp-brickquack",
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "dpp-brickquack-api",
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildFirst
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Deploying DPP API to Azure App Service" -ForegroundColor Cyan
Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor Gray
Write-Host "   App Name: $AppName" -ForegroundColor Gray
Write-Host ""

# Get project root (scripts/azure -> scripts -> root)
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$apiDir = Join-Path $projectRoot "api"

# Change to API directory
Push-Location $apiDir

try {
    # Create deployment package in the API directory
    $deployPackage = "deploy.zip"
    
    if (Test-Path $deployPackage) {
        Write-Host "🗑️  Removing old deployment package..." -ForegroundColor Yellow
        Remove-Item $deployPackage -Force
    }
    
    Write-Host "📦 Creating deployment package..." -ForegroundColor Cyan
    
    # Files to include in deployment
    $filesToZip = @(
        "dpp_api",
        "main.py",
        "pyproject.toml",
        "requirements.txt",
        "runtime.txt",
        "startup.sh"
    )
    
    # Create temporary directory
    $tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "dpp_deploy_$(Get-Date -Format 'yyyyMMddHHmmss')") -Force
    
    try {
        # Copy API files to temp directory
        foreach ($item in $filesToZip) {
            $source = Join-Path $apiDir $item
            if (Test-Path $source) {
                Copy-Item -Path $source -Destination $tempDir -Recurse -Force
            } else {
                Write-Host "⚠️  Warning: $item not found at $source" -ForegroundColor Yellow
            }
        }
        
        # Copy schemas from project root
        $schemasSource = Join-Path $projectRoot "schemas"
        if (Test-Path $schemasSource) {
            Copy-Item -Path $schemasSource -Destination $tempDir -Recurse -Force
        } else {
            Write-Host "⚠️  Warning: schemas directory not found at $schemasSource" -ForegroundColor Yellow
        }
        
        # Create .deployment file for Azure
        @"
[config]
SCM_DO_BUILD_DURING_DEPLOYMENT=true
"@ | Out-File -FilePath "$tempDir/.deployment" -Encoding utf8
        
        # Create ZIP
        Compress-Archive -Path "$tempDir/*" -DestinationPath $deployPackage -Force
        
        Write-Host "✅ Deployment package created: $deployPackage" -ForegroundColor Green
        
    } finally {
        # Clean up temp directory
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
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
    
    # Deploy to Azure
    Write-Host ""
    Write-Host "🚀 Deploying to Azure App Service..." -ForegroundColor Cyan
    Write-Host "   This may take a few minutes..." -ForegroundColor Gray
    
    az webapp deploy `
        --resource-group $ResourceGroup `
        --name $AppName `
        --src-path $deployPackage `
        --type zip `
        --async false
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
        
        # Get the app URL
        $appUrl = az webapp show --name $AppName --resource-group $ResourceGroup --query "defaultHostName" -o tsv
        
        Write-Host ""
        Write-Host "🌐 Your API is available at:" -ForegroundColor Cyan
        Write-Host "   https://$appUrl" -ForegroundColor White
        Write-Host "   https://$appUrl/docs" -ForegroundColor White
        Write-Host ""
        Write-Host "📊 View logs with:" -ForegroundColor Cyan
        Write-Host "   az webapp log tail --name $AppName --resource-group $ResourceGroup" -ForegroundColor Gray
        
    } else {
        Write-Host ""
        Write-Host "❌ Deployment failed!" -ForegroundColor Red
        Write-Host "   Check logs with: az webapp log tail --name $AppName --resource-group $ResourceGroup" -ForegroundColor Yellow
        exit 1
    }
    
} finally {
    Pop-Location
}
