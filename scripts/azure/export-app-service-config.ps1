#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Export Azure App Service configuration for reuse
.DESCRIPTION
    Exports configuration, app settings, connection strings, and generates
    infrastructure templates for the DPP App Services
.PARAMETER ResourceGroup
    The Azure resource group name
.PARAMETER ApiAppName
    The API App Service name
.PARAMETER PortalAppName
    The Portal App Service name (optional)
.PARAMETER OutputDir
    Directory to save exported configuration (defaults to configs/azure)
.PARAMETER Format
    Export format: json, bicep, terraform, or all (default: all)
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "dpp-brickquack",
    
    [Parameter(Mandatory=$false)]
    [string]$ApiAppName = "dpp-brickquack-api",
    
    [Parameter(Mandatory=$false)]
    [string]$PortalAppName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("json", "bicep", "terraform", "all")]
    [string]$Format = "all"
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Exporting Azure App Service Configuration" -ForegroundColor Cyan
Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor Gray
Write-Host "   API App: $ApiAppName" -ForegroundColor Gray
if ($PortalAppName) {
    Write-Host "   Portal App: $PortalAppName" -ForegroundColor Gray
}
Write-Host ""

# Get project root and set output directory
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $OutputDir) {
    $OutputDir = Join-Path $projectRoot "configs\azure"
}

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Check Azure login
Write-Host "🔐 Checking Azure login..." -ForegroundColor Cyan
$account = az account show 2>$null
if (-not $account) {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
$subscription = ($account | ConvertFrom-Json).name
Write-Host "✅ Logged in to subscription: $subscription" -ForegroundColor Green
Write-Host ""

# Function to export app service config
function Export-AppServiceConfig {
    param(
        [string]$AppName,
        [string]$ResourceGroup,
        [string]$OutputPrefix
    )
    
    Write-Host "📥 Exporting configuration for: $AppName" -ForegroundColor Cyan
    
    # Check if app exists
    $appExists = az webapp show --name $AppName --resource-group $ResourceGroup 2>$null
    if (-not $appExists) {
        Write-Host "⚠️  App '$AppName' not found, skipping..." -ForegroundColor Yellow
        return $null
    }
    
    # Get full app configuration
    Write-Host "   • Getting app details..." -ForegroundColor Gray
    $appConfig = az webapp show --name $AppName --resource-group $ResourceGroup | ConvertFrom-Json
    
    # Get app settings
    Write-Host "   • Getting app settings..." -ForegroundColor Gray
    $appSettings = az webapp config appsettings list --name $AppName --resource-group $ResourceGroup | ConvertFrom-Json
    
    # Get connection strings
    Write-Host "   • Getting connection strings..." -ForegroundColor Gray
    $connectionStrings = az webapp config connection-string list --name $AppName --resource-group $ResourceGroup | ConvertFrom-Json
    
    # Get deployment source config
    Write-Host "   • Getting deployment config..." -ForegroundColor Gray
    $deploymentConfig = az webapp deployment source show --name $AppName --resource-group $ResourceGroup 2>$null | ConvertFrom-Json
    
    # Get runtime configuration
    Write-Host "   • Getting runtime config..." -ForegroundColor Gray
    $runtimeConfig = az webapp config show --name $AppName --resource-group $ResourceGroup | ConvertFrom-Json
    
    # Create structured export
    $export = @{
        exportDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        subscription = $subscription
        resourceGroup = $ResourceGroup
        appName = $AppName
        location = $appConfig.location
        kind = $appConfig.kind
        sku = @{
            name = $appConfig.sku.name
            tier = $appConfig.sku.tier
            size = $appConfig.sku.size
            family = $appConfig.sku.family
            capacity = $appConfig.sku.capacity
        }
        runtime = @{
            linuxFxVersion = $runtimeConfig.linuxFxVersion
            alwaysOn = $runtimeConfig.alwaysOn
            http20Enabled = $runtimeConfig.http20Enabled
            minTlsVersion = $runtimeConfig.minTlsVersion
            ftpsState = $runtimeConfig.ftpsState
            pythonVersion = $runtimeConfig.pythonVersion
        }
        appSettings = @($appSettings | ForEach-Object { 
            @{
                name = $_.name
                value = if ($_.name -match "(PASSWORD|SECRET|KEY|TOKEN)") { "***REDACTED***" } else { $_.value }
                slotSetting = $_.slotSetting
            }
        })
        connectionStrings = @($connectionStrings.PSObject.Properties | ForEach-Object {
            @{
                name = $_.Name
                type = $_.Value.type
                value = "***REDACTED***"
            }
        })
        deployment = if ($deploymentConfig) {
            @{
                type = $deploymentConfig.type
                repoUrl = $deploymentConfig.repoUrl
                branch = $deploymentConfig.branch
            }
        } else { $null }
        defaultHostName = $appConfig.defaultHostName
        enabledHostNames = $appConfig.enabledHostNames
        httpsOnly = $appConfig.httpsOnly
        tags = $appConfig.tags
    }
    
    # Save JSON export
    $jsonFile = Join-Path $OutputDir "$OutputPrefix-config.json"
    $export | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding utf8
    Write-Host "   ✅ Saved: $jsonFile" -ForegroundColor Green
    
    return $export
}

# Function to generate Bicep template
function Generate-BicepTemplate {
    param(
        [object[]]$Configs
    )
    
    Write-Host ""
    Write-Host "📝 Generating Bicep template..." -ForegroundColor Cyan
    
    $bicepFile = Join-Path $OutputDir "app-services.bicep"
    
    $bicep = @"
// Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
// Azure App Services for DPP Project

@description('Location for all resources')
param location string = resourceGroup().location

@description('App Service Plan name')
param appServicePlanName string = 'dpp-app-service-plan'

@description('App Service Plan SKU')
param skuName string = '$($Configs[0].sku.name)'

@description('App Service Plan tier')
param skuTier string = '$($Configs[0].sku.tier)'

@description('Environment name (dev, staging, prod)')
param environment string = 'dev'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

"@

    foreach ($config in $Configs) {
        $appType = if ($config.appName -match "api") { "api" } else { "portal" }
        $bicep += @"

// $($config.appName) App Service
resource $($appType)AppService 'Microsoft.Web/sites@2022-09-01' = {
  name: '$($config.appName)-`${environment}'
  location: location
  kind: '$($config.kind)'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: $($config.httpsOnly.ToString().ToLower())
    siteConfig: {
      linuxFxVersion: '$($config.runtime.linuxFxVersion)'
      alwaysOn: $($config.runtime.alwaysOn.ToString().ToLower())
      http20Enabled: $($config.runtime.http20Enabled.ToString().ToLower())
      minTlsVersion: '$($config.runtime.minTlsVersion)'
      ftpsState: '$($config.runtime.ftpsState)'
      appSettings: [
"@
        
        foreach ($setting in $config.appSettings) {
            if ($setting.name -notmatch "WEBSITE_") {  # Skip system settings
                $bicep += @"

        {
          name: '$($setting.name)'
          value: '$($setting.value)'
        }
"@
            }
        }
        
        $bicep += @"

      ]
    }
  }
}

output $($appType)AppServiceName string = $($appType)AppService.name
output $($appType)AppServiceUrl string = $($appType)AppService.properties.defaultHostName
"@
    }
    
    $bicep | Out-File -FilePath $bicepFile -Encoding utf8
    Write-Host "   ✅ Saved: $bicepFile" -ForegroundColor Green
}

# Function to generate Terraform template
function Generate-TerraformTemplate {
    param(
        [object[]]$Configs
    )
    
    Write-Host ""
    Write-Host "📝 Generating Terraform template..." -ForegroundColor Cyan
    
    $tfFile = Join-Path $OutputDir "app-services.tf"
    
    $terraform = @"
# Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Azure App Services for DPP Project

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "$($Configs[0].location)"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "$ResourceGroup"
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "dpp-app-service-plan-`${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "$($Configs[0].sku.name)"
}

"@

    foreach ($config in $Configs) {
        $appType = if ($config.appName -match "api") { "api" } else { "portal" }
        $terraform += @"

# $($config.appName) App Service
resource "azurerm_linux_web_app" "$appType" {
  name                = "$($config.appName)-`${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = $($config.httpsOnly.ToString().ToLower())

  site_config {
    always_on         = $($config.runtime.alwaysOn.ToString().ToLower())
    http2_enabled     = $($config.runtime.http20Enabled.ToString().ToLower())
    minimum_tls_version = "$($config.runtime.minTlsVersion)"
    ftps_state        = "$($config.runtime.ftpsState)"
    
"@
        
        if ($config.runtime.linuxFxVersion -match "PYTHON\|(.+)") {
            $terraform += "    application_stack {`n"
            $terraform += "      python_version = `"$($Matches[1])`"`n"
            $terraform += "    }`n"
        }
        
        $terraform += "  }`n`n"
        
        # Add app settings
        $terraform += "  app_settings = {`n"
        foreach ($setting in $config.appSettings) {
            if ($setting.name -notmatch "WEBSITE_") {
                $terraform += "    `"$($setting.name)`" = `"$($setting.value)`"`n"
            }
        }
        $terraform += "  }`n"
        $terraform += "}`n`n"
        
        $terraform += @"
output "$($appType)_app_service_name" {
  value = azurerm_linux_web_app.$appType.name
}

output "$($appType)_app_service_url" {
  value = "https://`${azurerm_linux_web_app.$appType.default_hostname}"
}

"@
    }
    
    $terraform | Out-File -FilePath $tfFile -Encoding utf8
    Write-Host "   ✅ Saved: $tfFile" -ForegroundColor Green
    
    # Create tfvars template
    $tfvarsFile = Join-Path $OutputDir "terraform.tfvars.example"
    $tfvars = @"
# Terraform variables for DPP deployment
# Copy to terraform.tfvars and update with your values

location            = "$($Configs[0].location)"
resource_group_name = "$ResourceGroup"
environment         = "dev"

# Add sensitive values here (don't commit terraform.tfvars!)
# database_connection_string = "your-connection-string"
# jwt_secret = "your-jwt-secret"
"@
    $tfvars | Out-File -FilePath $tfvarsFile -Encoding utf8
    Write-Host "   ✅ Saved: $tfvarsFile" -ForegroundColor Green
}

# Function to generate deployment parameter file
function Generate-ParametersFile {
    param(
        [object[]]$Configs
    )
    
    Write-Host ""
    Write-Host "📝 Generating parameters file..." -ForegroundColor Cyan
    
    $paramsFile = Join-Path $OutputDir "parameters.json"
    
    $parameters = @{
        '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
        contentVersion = "1.0.0.0"
        parameters = @{
            location = @{
                value = $Configs[0].location
            }
            environment = @{
                value = "dev"
            }
            appServicePlanName = @{
                value = "dpp-app-service-plan"
            }
            skuName = @{
                value = $Configs[0].sku.name
            }
            skuTier = @{
                value = $Configs[0].sku.tier
            }
        }
    }
    
    $parameters | ConvertTo-Json -Depth 10 | Out-File -FilePath $paramsFile -Encoding utf8
    Write-Host "   ✅ Saved: $paramsFile" -ForegroundColor Green
}

# Export configurations
$exportedConfigs = @()

# Export API App Service
$apiConfig = Export-AppServiceConfig -AppName $ApiAppName -ResourceGroup $ResourceGroup -OutputPrefix "api"
if ($apiConfig) {
    $exportedConfigs += $apiConfig
}

# Export Portal App Service (if provided)
if ($PortalAppName) {
    Write-Host ""
    $portalConfig = Export-AppServiceConfig -AppName $PortalAppName -ResourceGroup $ResourceGroup -OutputPrefix "portal"
    if ($portalConfig) {
        $exportedConfigs += $portalConfig
    }
}

# Generate IaC templates based on format
if ($exportedConfigs.Count -gt 0) {
    if ($Format -eq "bicep" -or $Format -eq "all") {
        Generate-BicepTemplate -Configs $exportedConfigs
    }
    
    if ($Format -eq "terraform" -or $Format -eq "all") {
        Generate-TerraformTemplate -Configs $exportedConfigs
    }
    
    if ($Format -eq "bicep" -or $Format -eq "all") {
        Generate-ParametersFile -Configs $exportedConfigs
    }
    
    # Create README
    Write-Host ""
    Write-Host "📝 Generating README..." -ForegroundColor Cyan
    $readmeFile = Join-Path $OutputDir "README.md"
    $readme = @"
# DPP Azure App Service Configuration

Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Exported Configurations

This directory contains exported configurations and Infrastructure as Code (IaC) templates for the DPP Azure App Services.

### Files

- **JSON Configs**: Raw configuration exports with app settings, runtime config, and metadata
  - ``api-config.json`` - API App Service configuration
$(if ($PortalAppName) { "  - ``portal-config.json`` - Portal App Service configuration`n" })

- **Bicep Template**: Azure Resource Manager template in Bicep syntax
  - ``app-services.bicep`` - Complete infrastructure template
  - ``parameters.json`` - Parameter file for Bicep deployment

- **Terraform Template**: Terraform configuration files
  - ``app-services.tf`` - Terraform resource definitions
  - ``terraform.tfvars.example`` - Example variables file

## Usage

### Deploy with Bicep

``````bash
# Login to Azure
az login

# Create or use existing resource group
az group create --name dpp-dev --location $($exportedConfigs[0].location)

# Deploy the template
az deployment group create \
  --resource-group dpp-dev \
  --template-file app-services.bicep \
  --parameters parameters.json
``````

### Deploy with Terraform

``````bash
# Initialize Terraform
terraform init

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Plan deployment
terraform plan

# Apply deployment
terraform apply
``````

## Security Notes

⚠️ **Important**: 
- Sensitive values (passwords, secrets, keys, tokens) have been redacted in the JSON exports
- Update the templates with your actual values before deployment
- Never commit sensitive values to version control
- Use Azure Key Vault or environment variables for secrets in production

## Environment Variables

The following app settings need to be configured with actual values:

$($exportedConfigs | ForEach-Object {
    $appName = $_.appName
    if ($_.appSettings) {
        $_.appSettings | Where-Object { $_.value -eq "***REDACTED***" } | ForEach-Object {
            "- ``$($_.name)`` ($appName)`n"
        }
    }
})

## Resource Group

- **Name**: $ResourceGroup
- **Location**: $($exportedConfigs[0].location)
- **Subscription**: $subscription

## App Services

$($exportedConfigs | ForEach-Object {
@"
### $($_.appName)
- **SKU**: $($_.sku.tier) ($($_.sku.name))
- **Runtime**: $($_.runtime.linuxFxVersion)
- **URL**: https://$($_.defaultHostName)
- **HTTPS Only**: $($_.httpsOnly)
- **Always On**: $($_.runtime.alwaysOn)

"@
})

## Next Steps

1. Review the exported configurations
2. Update sensitive values in the templates
3. Test deployment in a dev/staging environment
4. Adjust SKUs and scaling settings as needed
5. Configure CI/CD pipelines for automated deployments

## Additional Resources

- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
"@
    $readme | Out-File -FilePath $readmeFile -Encoding utf8
    Write-Host "   ✅ Saved: $readmeFile" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "✅ Export complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 Configuration saved to: $OutputDir" -ForegroundColor Cyan
    Write-Host "   • JSON configs with current settings" -ForegroundColor Gray
    if ($Format -eq "bicep" -or $Format -eq "all") {
        Write-Host "   • Bicep template for Azure deployment" -ForegroundColor Gray
    }
    if ($Format -eq "terraform" -or $Format -eq "all") {
        Write-Host "   • Terraform template for infrastructure" -ForegroundColor Gray
    }
    Write-Host "   • README with usage instructions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  Remember to update sensitive values before deploying!" -ForegroundColor Yellow
    
} else {
    Write-Host ""
    Write-Host "❌ No configurations were exported" -ForegroundColor Red
}
