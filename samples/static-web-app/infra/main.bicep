// Main Bicep template for Static Web App sample
// This template creates a Static Web App for hosting frontend applications

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('The name of the environment. This will be used to generate resource names.')
param environmentName string

@description('Static Web App SKU')
@allowed(['Free', 'Standard'])
param staticWebAppSku string = 'Free'

@description('GitHub repository URL (optional - can be configured later)')
param repositoryUrl string = ''

@description('GitHub repository branch (optional - can be configured later)')
param repositoryBranch string = 'main'

@description('GitHub repository token (optional - can be configured later)')
@secure()
param repositoryToken string = ''

@description('Build properties for the static web app')
param buildProperties object = {
  appLocation: '/'
  apiLocation: 'api'
  outputLocation: 'dist'
}

@description('Tags for all resources')
param tags object = {}

// Generate unique resource names using the environment name
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName))
var staticWebAppName = 'swa-${environmentName}-${resourceToken}'

// Merge default tags with provided tags
var defaultTags = {
  'azd-env-name': environmentName
  'sample-type': 'static-web-app'
}
var allTags = union(defaultTags, tags)

// Static Web App
resource staticWebApp 'Microsoft.Web/staticSites@2024-04-01' = {
  name: staticWebAppName
  location: location
  tags: union(allTags, { 'azd-service-name': 'web' })
  sku: {
    name: staticWebAppSku
    tier: staticWebAppSku
  }
  properties: {
    repositoryUrl: !empty(repositoryUrl) ? repositoryUrl : null
    branch: !empty(repositoryBranch) ? repositoryBranch : null
    repositoryToken: !empty(repositoryToken) ? repositoryToken : null
    buildProperties: buildProperties
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    provider: 'GitHub'
  }
}

// Outputs for use by the application
output staticWebAppUrl string = 'https://${staticWebApp.properties.defaultHostname}'
output staticWebAppName string = staticWebApp.name
output staticWebAppDefaultHostname string = staticWebApp.properties.defaultHostname
