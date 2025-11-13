#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy DPP Portal to Azure App Service
.DESCRIPTION
    Deploys the Next.js portal to Azure App Service using ZIP deployment.
    Excludes node_modules and .next to reduce deployment size and time.
    Azure will rebuild the app during deployment.
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

Write-Host ""
Write-Host "🚀 Deploying DPP Portal to Azure App Service" -ForegroundColor Cyan
Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor Gray
Write-Host "   App Name: $AppName" -ForegroundColor Gray
Write-Host ""

# Change to portal directory
$portalDir = Join-Path $PSScriptRoot "portal"
Push-Location $portalDir

try {
    # Create deployment package
    $deployPackage = "deploy.zip"
    $tempDir = Join-Path $PSScriptRoot "temp_portal_deploy"
    
    if (Test-Path $deployPackage) {
        Write-Host "🗑️  Removing old deployment package..." -ForegroundColor Yellow
        Remove-Item $deployPackage -Force
    }
    
    Write-Host "📦 Creating deployment package (excluding node_modules and .next)..." -ForegroundColor Cyan
    
    # Create temporary directory
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    try {
        # Files and directories to include (everything except node_modules and .next)
        # Note: server.js and startup.sh have enhanced error handling and diagnostics
        $itemsToInclude = @(
            "app",                      # Next.js app directory
            "package.json",             # Dependencies (includes Next.js with Node 18-20 compatibility)
            "package-lock.json",        # Exact dependency versions
            "next.config.js",           # Next.js configuration
            "tailwind.config.ts",       # Tailwind CSS configuration
            "tsconfig.json",            # TypeScript configuration
            "postcss.config.js",        # PostCSS configuration
            "next-env.d.ts",            # Next.js type definitions
            "server.js",                # Custom server with enhanced diagnostics
            "startup.sh",               # Azure startup script with dependency checks
            "web.config",               # IIS configuration (if needed)
            ".deployment",              # Azure deployment configuration
            "deploy.sh",                # Deployment helper script
            ".npmrc",                   # NPM configuration
            ".env.production"           # Production environment variables
        )
        
        Write-Host "   Copying files..." -ForegroundColor Gray
        foreach ($item in $itemsToInclude) {
            $source = Join-Path $portalDir $item
            if (Test-Path $source) {
                $dest = Join-Path $tempDir $item
                Copy-Item -Path $source -Destination $dest -Recurse -Force
                Write-Host "   ✓ $item" -ForegroundColor DarkGray
            } else {
                Write-Host "   ⚠ $item (not found, skipping)" -ForegroundColor Yellow
            }
        }
        
        Write-Host "   Creating ZIP archive..." -ForegroundColor Gray
        Compress-Archive -Path "$tempDir\*" -DestinationPath $deployPackage -Force
        
        $zipSize = (Get-Item $deployPackage).Length / 1MB
        $sizeMessage = "✅ Deployment package created: $deployPackage ({0:N2} MB)" -f $zipSize
        Write-Host $sizeMessage -ForegroundColor Green
        Write-Host "   (Excluded node_modules and .next - Azure will build them)" -ForegroundColor DarkGray
        Write-Host ""
        
    } finally {
        # Clean up temp directory
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Check if logged in to Azure
    Write-Host "🔐 Checking Azure login..." -ForegroundColor Cyan
    $account = az account show 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host ""
    
    # Verify app exists
    Write-Host "🔍 Verifying App Service exists..." -ForegroundColor Cyan
    $app = az webapp show --name $AppName --resource-group $ResourceGroup 2>$null | ConvertFrom-Json
    if (-not $app) {
        Write-Host "❌ App Service '$AppName' not found in resource group '$ResourceGroup'" -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 Create the App Service first with:" -ForegroundColor Yellow
        Write-Host "   .\configure-azure-portal.ps1" -ForegroundColor Gray
        exit 1
    }
    Write-Host "✅ App Service found: $($app.name)" -ForegroundColor Green
    Write-Host ""
    
    # Configure app settings for build
    Write-Host "⚙️  Configuring App Service settings..." -ForegroundColor Cyan
    az webapp config appsettings set `
        --resource-group $ResourceGroup `
        --name $AppName `
        --settings `
            "SCM_DO_BUILD_DURING_DEPLOYMENT=true" `
            "WEBSITE_NODE_DEFAULT_VERSION=20-lts" `
            "NODE_ENV=production" `
            "NPM_CONFIG_PRODUCTION=false" `
            "API_BASE=https://dpp-brickquack-api.azurewebsites.net" `
        --output none
    
    Write-Host "   ✓ App settings configured" -ForegroundColor Gray
    
    # Set the startup command to use our startup script
    Write-Host "   Setting startup command..." -ForegroundColor Gray
    az webapp config set `
        --resource-group $ResourceGroup `
        --name $AppName `
        --startup-file "bash startup.sh" `
        --output none
    
    Write-Host "✅ Settings and startup command configured" -ForegroundColor Green
    Write-Host "   Startup: bash startup.sh" -ForegroundColor DarkGray
    Write-Host ""
    
    # Deploy to Azure
    Write-Host "🚀 Deploying to Azure App Service..." -ForegroundColor Cyan
    Write-Host "   Uploading package and building on Azure..." -ForegroundColor Gray
    Write-Host "   This will take 2-3 minutes..." -ForegroundColor Gray
    Write-Host ""
    
    $deployResult = az webapp deploy `
        --resource-group $ResourceGroup `
        --name $AppName `
        --src-path $deployPackage `
        --type zip `
        --async false `
        2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
        
        # Get the app URL
        $appUrl = az webapp show --name $AppName --resource-group $ResourceGroup --query "defaultHostName" -o tsv
        
        Write-Host ""
        Write-Host "🌐 Your Portal is available at:" -ForegroundColor Cyan
        Write-Host "   https://$appUrl" -ForegroundColor White
        Write-Host ""
        Write-Host "📝 Note: The app may take 1-2 minutes to fully start after deployment" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "📊 Monitor with:" -ForegroundColor Cyan
        Write-Host "   az webapp log tail --name $AppName --resource-group $ResourceGroup" -ForegroundColor Gray
        Write-Host ""
        
    } else {
        Write-Host ""
        Write-Host "❌ Deployment failed!" -ForegroundColor Red
        Write-Host "   Error: $deployResult" -ForegroundColor Red
        Write-Host ""
        Write-Host "📊 Check logs with:" -ForegroundColor Yellow
        Write-Host "   az webapp log tail --name $AppName --resource-group $ResourceGroup" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
    
} catch {
    Write-Host ""
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host ""
    exit 1
} finally {
    Pop-Location
}
