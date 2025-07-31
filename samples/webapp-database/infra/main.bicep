// Main Bicep template for Web App + SQL Database sample
// This template creates a simple web application with Azure SQL Database

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('The name of the environment. This will be used to generate resource names.')
param environmentName string

@description('The SKU of the App Service Plan. Choose from Basic, Standard, Premium tiers.')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1V2', 'P2V2', 'P3V2'])
param appServicePlanSku string = 'B1'

@description('SQL Database edition')
@allowed(['Basic', 'Standard', 'Premium'])
param sqlDatabaseSku string = 'Basic'

@description('Administrator username for the SQL server')
param sqlAdminUsername string = 'sqladmin'

@secure()
@description('Administrator password for the SQL server')
param sqlAdminPassword string

@description('Tags for all resources')
param tags object = {}

// Generate unique resource names using the environment name
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName))
var appServicePlanName = 'asp-${environmentName}-${resourceToken}'
var webAppName = 'app-${environmentName}-${resourceToken}'
var sqlServerName = 'sql-${environmentName}-${resourceToken}'
var sqlDatabaseName = 'sqldb-${environmentName}-${resourceToken}'

// Merge default tags with provided tags
var defaultTags = {
  'azd-env-name': environmentName
  'sample-type': 'webapp-database'
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

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: sqlServerName
  location: location
  tags: allTags
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: allTags
  sku: {
    name: sqlDatabaseSku
    tier: sqlDatabaseSku
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

// SQL Server firewall rule to allow Azure services
resource sqlFirewallRuleAzure 'Microsoft.Sql/servers/firewallRules@2021-11-01' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Web App
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
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
          type: 'SQLAzure'
        }
      ]
      appSettings: [
        {
          name: 'AZURE_SQL_CONNECTION_STRING'
          value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
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
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
