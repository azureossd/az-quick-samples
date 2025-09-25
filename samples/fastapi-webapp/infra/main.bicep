// Main Bicep template for FastAPI Web App sample
// This template creates a FastAPI application on Azure App Service Linux

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('The name of the environment. This will be used to generate resource names.')
param environmentName string

@description('The SKU of the App Service Plan.')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1V2', 'P2V2', 'P3V2'])
param appServicePlanSku string = 'B1'

@description('Tags for all resources')
param tags object = {}

// Generate unique resource names using the environment name
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName))
var appServicePlanName = 'asp-${environmentName}-${resourceToken}'
var webAppName = 'app-${environmentName}-${resourceToken}'

// Merge default tags with provided tags
var defaultTags = {
  'azd-env-name': environmentName
  'sample-type': 'fastapi-webapp'
}
var allTags = union(defaultTags, tags)

// App Service Plan for Linux
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  tags: allTags
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true // Linux app service plan for Python
  }
  kind: 'linux'
}

// Web App for FastAPI Application
resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  tags: union(allTags, { 'azd-service-name': 'web' })
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      linuxFxVersion: 'PYTHON|3.11'
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'ENVIRONMENT'
          value: 'production'
        }
        {
          name: 'PYTHONPATH'
          value: '/home/site/wwwroot'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
        {
          name: 'DISABLE_COLLECTSTATIC'
          value: '1'
        }
      ]
      alwaysOn: appServicePlanSku != 'B1' ? true : false
      healthCheckPath: '/health'
    }
  }
}

// Outputs for use by the application
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output appServicePlanName string = appServicePlan.name
