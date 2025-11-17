# Generated on 2025-11-17 13:52:43
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
  default     = "Sweden Central"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "dpp-brickquack"
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "dpp-app-service-plan-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = ""
}

# dpp-brickquack-api App Service
resource "azurerm_linux_web_app" "api" {
  name                = "dpp-brickquack-api-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = false

  site_config {
    always_on         = false
    http2_enabled     = false
    minimum_tls_version = "1.2"
    ftps_state        = "FtpsOnly"
        application_stack {
      python_version = "3.12"
    }
  }

  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = "InstrumentationKey=0aaf738d-2c47-4dcd-9b48-1b3352cd8d08;IngestionEndpoint=https://swedencentral-0.in.applicationinsights.azure.com/;LiveEndpoint=https://swedencentral.livediagnostics.monitor.azure.com/;ApplicationId=5b9f6c0e-fdf8-4434-8345-421707abbdf6"
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    "APPLICATIONINSIGHTSAGENT_EXTENSION_ENABLED" = "true"
    "DEMO_MODE" = "1"
    "ALLOW_ANON_PUBLIC" = "1"
  }
}

output "api_app_service_name" {
  value = azurerm_linux_web_app.api.name
}

output "api_app_service_url" {
  value = "https://${azurerm_linux_web_app.api.default_hostname}"
}

# dpp-brickquack App Service
resource "azurerm_linux_web_app" "portal" {
  name                = "dpp-brickquack-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = false

  site_config {
    always_on         = false
    http2_enabled     = false
    minimum_tls_version = "1.2"
    ftps_state        = "FtpsOnly"
      }

  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = "InstrumentationKey=0aaf738d-2c47-4dcd-9b48-1b3352cd8d08;IngestionEndpoint=https://swedencentral-0.in.applicationinsights.azure.com/;LiveEndpoint=https://swedencentral.livediagnostics.monitor.azure.com/;ApplicationId=5b9f6c0e-fdf8-4434-8345-421707abbdf6"
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    "APPLICATIONINSIGHTSAGENT_EXTENSION_ENABLED" = "true"
    "NEXT_PUBLIC_API_URL" = "https://dpp-brickquack-api.azurewebsites.net"
    "NEXT_PUBLIC_API_BASE" = "https://dpp-brickquack-api.azurewebsites.net"
    "API_URL" = "https://dpp-brickquack-api.azurewebsites.net"
    "NODE_ENV" = "production"
    "API_BASE" = "https://dpp-brickquack-api.azurewebsites.net"
  }
}

output "portal_app_service_name" {
  value = azurerm_linux_web_app.portal.name
}

output "portal_app_service_url" {
  value = "https://${azurerm_linux_web_app.portal.default_hostname}"
}

