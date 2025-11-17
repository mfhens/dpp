# DPP Azure App Service Configuration

Generated on: 2025-11-17 13:52:43

## Exported Configurations

This directory contains exported configurations and Infrastructure as Code (IaC) templates for the DPP Azure App Services.

### Files

- **JSON Configs**: Raw configuration exports with app settings, runtime config, and metadata
  - `api-config.json` - API App Service configuration
  - `portal-config.json` - Portal App Service configuration


- **Bicep Template**: Azure Resource Manager template in Bicep syntax
  - `app-services.bicep` - Complete infrastructure template
  - `parameters.json` - Parameter file for Bicep deployment

- **Terraform Template**: Terraform configuration files
  - `app-services.tf` - Terraform resource definitions
  - `terraform.tfvars.example` - Example variables file

## Usage

### Deploy with Bicep

```bash
# Login to Azure
az login

# Create or use existing resource group
az group create --name dpp-dev --location Sweden Central

# Deploy the template
az deployment group create \
  --resource-group dpp-dev \
  --template-file app-services.bicep \
  --parameters parameters.json
```

### Deploy with Terraform

```bash
# Initialize Terraform
terraform init

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Plan deployment
terraform plan

# Apply deployment
terraform apply
```

## Security Notes

⚠️ **Important**: 
- Sensitive values (passwords, secrets, keys, tokens) have been redacted in the JSON exports
- Update the templates with your actual values before deployment
- Never commit sensitive values to version control
- Use Azure Key Vault or environment variables for secrets in production

## Environment Variables

The following app settings need to be configured with actual values:



## Resource Group

- **Name**: dpp-brickquack
- **Location**: Sweden Central
- **Subscription**: Azure subscription 1

## App Services

### dpp-brickquack-api
- **SKU**:  ()
- **Runtime**: PYTHON|3.12
- **URL**: https://dpp-brickquack-api.azurewebsites.net
- **HTTPS Only**: False
- **Always On**: False
 ### dpp-brickquack
- **SKU**:  ()
- **Runtime**: NODE|20-lts
- **URL**: https://dpp-brickquack.azurewebsites.net
- **HTTPS Only**: False
- **Always On**: False


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
