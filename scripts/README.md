# Scripts Directory

This directory contains all the PowerShell scripts for the DPP project, organized by purpose.

## Directory Structure

### `/azure` - Azure Deployment & Management
Scripts for deploying and managing resources in Azure:
- `configure-azure-portal.ps1` - Configure Azure portal settings
- `deploy-to-azure.ps1` - Main Azure deployment script
- `deploy-portal-to-azure.ps1` - Deploy the portal to Azure
- `enable-demo-mode-azure.ps1` - Enable demo mode for Azure deployment
- `reset-demo-database-azure.ps1` - Reset the demo database in Azure
- `upload-planning-insights-azure.ps1` - Upload planning insights to Azure

### `/docker` - Local Docker Operations
Scripts for running and managing Docker containers locally:
- `run-local.ps1` - Run the full application stack locally with Docker
- `run-api-local.ps1` - Run only the API locally with Docker
- `view-logs.ps1` - View Docker container logs
- `watch-planning-insights.ps1` - Watch and monitor planning insights

### `/demo` - Demo & POC Scripts
Scripts for demonstration and proof-of-concept purposes:
- `demo-poc-azure.ps1` - Azure POC demo script
- `run-demo.ps1` - Run the application in demo mode

### `/setup` - Setup & Configuration
Scripts for initial setup and verification:
- `setup-secrets.ps1` - Set up required secrets for the application
- `seed-database.ps1` - Seed the database with initial data
- `verify-secrets.ps1` - Verify that all required secrets are configured
- `verify-api-setup.ps1` - Verify that the API is properly set up

## Usage

Run any script from the project root directory:

```powershell
# Azure deployment
.\scripts\azure\deploy-to-azure.ps1

# Local Docker development
.\scripts\docker\run-local.ps1

# Setup
.\scripts\setup\setup-secrets.ps1
```

## Prerequisites

- PowerShell 7.0 or later
- Docker Desktop (for Docker scripts)
- Azure CLI (for Azure scripts)
- Appropriate permissions and credentials
