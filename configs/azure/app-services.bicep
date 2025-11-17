// Generated on 2025-11-17 13:52:43
// Azure App Services for DPP Project

@description('Location for all resources')
param location string = resourceGroup().location

@description('App Service Plan name')
param appServicePlanName string = 'dpp-app-service-plan'

@description('App Service Plan SKU')
param skuName string = ''

@description('App Service Plan tier')
param skuTier string = ''

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

// dpp-brickquack-api App Service
resource apiAppService 'Microsoft.Web/sites@2022-09-01' = {
  name: 'dpp-brickquack-api-${environment}'
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: false
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.12'
      alwaysOn: false
      http20Enabled: false
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=0aaf738d-2c47-4dcd-9b48-1b3352cd8d08;IngestionEndpoint=https://swedencentral-0.in.applicationinsights.azure.com/;LiveEndpoint=https://swedencentral.livediagnostics.monitor.azure.com/;ApplicationId=5b9f6c0e-fdf8-4434-8345-421707abbdf6'
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPLICATIONINSIGHTSAGENT_EXTENSION_ENABLED'
          value: 'true'
        }
        {
          name: 'DEMO_MODE'
          value: '1'
        }
        {
          name: 'ALLOW_ANON_PUBLIC'
          value: '1'
        }
      ]
    }
  }
}

output apiAppServiceName string = apiAppService.name
output apiAppServiceUrl string = apiAppService.properties.defaultHostName
// dpp-brickquack App Service
resource portalAppService 'Microsoft.Web/sites@2022-09-01' = {
  name: 'dpp-brickquack-${environment}'
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: false
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: false
      http20Enabled: false
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=0aaf738d-2c47-4dcd-9b48-1b3352cd8d08;IngestionEndpoint=https://swedencentral-0.in.applicationinsights.azure.com/;LiveEndpoint=https://swedencentral.livediagnostics.monitor.azure.com/;ApplicationId=5b9f6c0e-fdf8-4434-8345-421707abbdf6'
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPLICATIONINSIGHTSAGENT_EXTENSION_ENABLED'
          value: 'true'
        }
        {
          name: 'NEXT_PUBLIC_API_URL'
          value: 'https://dpp-brickquack-api.azurewebsites.net'
        }
        {
          name: 'NEXT_PUBLIC_API_BASE'
          value: 'https://dpp-brickquack-api.azurewebsites.net'
        }
        {
          name: 'API_URL'
          value: 'https://dpp-brickquack-api.azurewebsites.net'
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'API_BASE'
          value: 'https://dpp-brickquack-api.azurewebsites.net'
        }
      ]
    }
  }
}

output portalAppServiceName string = portalAppService.name
output portalAppServiceUrl string = portalAppService.properties.defaultHostName
