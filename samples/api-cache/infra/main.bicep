// Main Bicep template for API + Redis Cache sample
// This template creates a REST API with Azure Cache for Redis

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('The name of the environment. This will be used to generate resource names.')
param environmentName string

@description('The SKU of the App Service Plan.')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1V2', 'P2V2', 'P3V2'])
param appServicePlanSku string = 'B1'

@description('Redis Cache SKU')
@allowed(['Basic', 'Standard', 'Premium'])
param redisCacheSku string = 'Basic'

@description('Redis Cache size')
@allowed(['C0', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6'])
param redisCacheSize string = 'C0'

@description('Tags for all resources')
param tags object = {}

// Generate unique resource names using the environment name
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName))
var appServicePlanName = 'asp-${environmentName}-${resourceToken}'
var webAppName = 'app-${environmentName}-${resourceToken}'
var redisCacheName = 'redis-${environmentName}-${resourceToken}'

// Merge default tags with provided tags
var defaultTags = {
  'azd-env-name': environmentName
  'sample-type': 'api-cache'
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
    reserved: false // Windows app service plan
  }
}

// Redis Cache
resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisCacheName
  location: location
  tags: allTags
  properties: {
    sku: {
      name: redisCacheSku
      family: startsWith(redisCacheSize, 'P') ? 'P' : 'C'
      capacity: int(substring(redisCacheSize, 1, 1))
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
}

// Web App for API
resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  tags: union(allTags, { 'azd-service-name': 'api' })
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'REDIS_CONNECTION_STRING'
          value: '${redisCache.properties.hostName}:${redisCache.properties.sslPort},password=${redisCache.listKeys().primaryKey},ssl=True,abortConnect=False'
        }
        {
          name: 'REDIS_HOST'
          value: redisCache.properties.hostName
        }
        {
          name: 'REDIS_PORT'
          value: string(redisCache.properties.sslPort)
        }
        {
          name: 'REDIS_SSL'
          value: 'true'
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
      ]
      use32BitWorkerProcess: false
      alwaysOn: appServicePlanSku != 'B1' ? true : false
    }
  }
}

// Outputs for use by the application
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output redisCacheName string = redisCache.name
output redisCacheHostName string = redisCache.properties.hostName
output redisCachePort int = redisCache.properties.sslPort
