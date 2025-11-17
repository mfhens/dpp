# Azure Deployment Scripts

This directory contains scripts for deploying and managing the DPP application on Azure.

## Scripts

### deploy-to-azure.ps1

Deploys the DPP API to Azure App Service using ZIP deployment.

**Usage:**
```powershell
# Deploy with default settings
.\deploy-to-azure.ps1

# Deploy to specific resource group and app
.\deploy-to-azure.ps1 -ResourceGroup "my-rg" -AppName "my-app-api"
```

**Parameters:**
- `-ResourceGroup`: Azure resource group name (default: "dpp-brickquack")
- `-AppName`: Azure App Service name (default: "dpp-brickquack-api")
- `-BuildFirst`: Build/prepare deployment package first (switch)

### export-app-service-config.ps1

Exports existing Azure App Service configurations and generates Infrastructure as Code (IaC) templates for redeployment.

**Usage:**
```powershell
# Export API configuration with all formats
.\export-app-service-config.ps1

# Export both API and Portal configurations
.\export-app-service-config.ps1 -PortalAppName "dpp-brickquack-portal"

# Export only Bicep template
.\export-app-service-config.ps1 -Format bicep

# Export to custom directory
.\export-app-service-config.ps1 -OutputDir "C:\backups\azure"
```

**Parameters:**
- `-ResourceGroup`: Azure resource group name (default: "dpp-brickquack")
- `-ApiAppName`: API App Service name (default: "dpp-brickquack-api")
- `-PortalAppName`: Portal App Service name (optional)
- `-OutputDir`: Output directory (default: "configs/azure")
- `-Format`: Export format - json, bicep, terraform, or all (default: all)

**Output:**
- JSON configuration files with current settings
- Bicep template for Azure Resource Manager deployment
- Terraform template for infrastructure provisioning
- Parameters file for customization
- README with deployment instructions

## Prerequisites

### Azure CLI

All scripts require the Azure CLI to be installed and authenticated.

**Install Azure CLI:**
- Windows: `winget install Microsoft.AzureCLI`
- Or download from: https://aka.ms/installazurecliwindows

**Login:**
```powershell
az login
```

**Verify:**
```powershell
az account show
```

## Workflow

### Initial Setup

1. Export existing configuration:
   ```powershell
   .\export-app-service-config.ps1
   ```

2. Review exported files in `configs/azure/`

3. Update sensitive values in templates

### Deployment

1. Deploy API to existing App Service:
   ```powershell
   .\deploy-to-azure.ps1
   ```

2. View logs:
   ```powershell
   az webapp log tail --name dpp-brickquack-api --resource-group dpp-brickquack
   ```

### Redeployment to New Environment

Use the exported Bicep or Terraform templates:

**With Bicep:**
```powershell
cd ..\..\configs\azure
az deployment group create `
  --resource-group dpp-staging `
  --template-file app-services.bicep `
  --parameters parameters.json `
  --parameters environment=staging
```

**With Terraform:**
```powershell
cd ..\..\configs\azure
terraform init
terraform plan -var="environment=staging"
terraform apply
```

## Security Best Practices

- Never commit sensitive values (passwords, secrets, connection strings)
- Use Azure Key Vault for production secrets
- Review exported configs before sharing
- Rotate secrets regularly
- Use managed identities when possible

## Troubleshooting

### Script Execution Policy

If you get an execution policy error:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Azure CLI Not Found

Ensure Azure CLI is in your PATH:
```powershell
az --version
```

### App Service Not Found

Verify your resource group and app name:
```powershell
az webapp list --resource-group dpp-brickquack --output table
```

### Deployment Failures

Check deployment logs:
```powershell
az webapp log tail --name <app-name> --resource-group <rg-name>
```

## Related Documentation

- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
