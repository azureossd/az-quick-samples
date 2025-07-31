# Web App + SQL Database Sample

This sample demonstrates deploying a simple web application with an Azure SQL Database using Azure Developer CLI (azd).

## Architecture

- **Azure App Service**: Hosts the web application
- **Azure SQL Database**: Stores application data
- **App Service Plan**: Compute resources for the web app

## Resources Created

1. App Service Plan (Basic B1 tier by default)
2. Azure SQL Server with firewall rules
3. Azure SQL Database (Basic tier by default)
4. Web App with connection string configuration

## Prerequisites

- [Azure Developer CLI (azd)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- An Azure subscription

## Deployment

### Quick Deploy

From the root of this repository, run:

```bash
# Windows PowerShell
.\deploy-sample.ps1

# Select option 1 for "Web App + SQL Database"
```

### Manual Deploy

1. Navigate to this directory:
   ```bash
   cd samples/webapp-database
   ```

2. Initialize azd:
   ```bash
   azd init --environment dev
   ```

3. Set the SQL admin password:
   ```bash
   azd env set SQL_ADMIN_PASSWORD "YourSecureP@ssw0rd!"
   ```

4. Deploy:
   ```bash
   azd up
   ```

## Configuration

You can customize the deployment by modifying the parameters in `infra/main.parameters.json`:

- `appServicePlanSku`: App Service Plan SKU (B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2)
- `sqlDatabaseSku`: SQL Database edition (Basic, Standard, Premium)
- `sqlAdminUsername`: SQL Server administrator username (default: sqladmin)

## Connection String

The web app is automatically configured with a connection string named `DefaultConnection` that points to the SQL database. You can access it in your application using:

- **ASP.NET Core**: `Configuration.GetConnectionString("DefaultConnection")`
- **Environment Variable**: `AZURE_SQL_CONNECTION_STRING`

## Security Considerations

- SQL Server is configured to accept connections from Azure services only
- Web app uses HTTPS only
- Minimum TLS version is set to 1.2
- SQL admin password should be stored securely (consider using Azure Key Vault for production)

## Clean Up

To remove all resources:

```bash
azd down
```

## Estimated Costs

With default configuration (Basic tiers):
- App Service Plan B1: ~$13/month
- SQL Database Basic: ~$5/month
- Total: ~$18/month

*Costs may vary by region and actual usage.*
