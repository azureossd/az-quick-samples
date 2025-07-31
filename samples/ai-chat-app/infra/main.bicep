// Main Bicep template for AI Chat App sample
// This template creates a chat application with Azure OpenAI Service

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('The name of the environment. This will be used to generate resource names.')
param environmentName string

@description('The SKU of the App Service Plan.')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1V2', 'P2V2', 'P3V2'])
param appServicePlanSku string = 'B1'

@description('OpenAI Service SKU')
@allowed(['S0'])
param openAiSku string = 'S0'

@description('OpenAI model deployment name')
param modelDeploymentName string = 'gpt-35-turbo'

@description('OpenAI model name')
param modelName string = 'gpt-35-turbo'

@description('OpenAI model version')
param modelVersion string = '0613'

@description('Tags for all resources')
param tags object = {}

// Generate unique resource names using the environment name
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName))
var appServicePlanName = 'asp-${environmentName}-${resourceToken}'
var webAppName = 'app-${environmentName}-${resourceToken}'
var openAiName = 'openai-${environmentName}-${resourceToken}'

// Merge default tags with provided tags
var defaultTags = {
  'azd-env-name': environmentName
  'sample-type': 'ai-chat-app'
}
var allTags = union(defaultTags, tags)

// App Service Plan
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
}

// Azure OpenAI Service
resource openAiService 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  tags: allTags
  kind: 'OpenAI'
  sku: {
    name: openAiSku
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// OpenAI Model Deployment
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAiService
  name: modelDeploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    raiPolicyName: 'Microsoft.Default'
  }
  sku: {
    name: 'Standard'
    capacity: 10
  }
}

// Web App for Chat Application
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
          name: 'AZURE_OPENAI_ENDPOINT'
          value: openAiService.properties.endpoint
        }
        {
          name: 'AZURE_OPENAI_API_KEY'
          value: openAiService.listKeys().key1
        }
        {
          name: 'AZURE_OPENAI_DEPLOYMENT_NAME'
          value: modelDeploymentName
        }
        {
          name: 'AZURE_OPENAI_MODEL_NAME'
          value: modelName
        }
        {
          name: 'AZURE_OPENAI_API_VERSION'
          value: '2024-06-01'
        }
        {
          name: 'FLASK_ENV'
          value: 'production'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
      alwaysOn: appServicePlanSku != 'B1' ? true : false
    }
  }
  dependsOn: [
    modelDeployment
  ]
}

// Outputs for use by the application
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output openAiEndpoint string = openAiService.properties.endpoint
output openAiName string = openAiService.name
output modelDeploymentName string = modelDeployment.name
