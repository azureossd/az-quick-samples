# Azure Quick Samples

A collection of ready-to-deploy Azure sample projects using Azure Developer CLI (azd). Each sample includes Bicep templates, configuration files, and deployment instructions for common Azure scenarios.

## Available Samples

1. **Web App + Database** - Simple web application with Azure SQL Database
2. **Container App** - Containerized application with Azure Container Apps
3. **FastAPI Web App** - Python FastAPI application with RESTful API
4. **Function App + Storage** - Azure Functions with Blob Storage
5. **Static Web App** - Frontend application with Azure Static Web Apps
6. **API + Cache** - REST API with Azure Cache for Redis
7. **AI Chat App** - Chat application with Azure OpenAI

## Quick Start

### Prerequisites
- [Azure Developer CLI (azd)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- An Azure subscription

### Automated Deployment

Run the deployment script to select and deploy a sample:

```bash
# Windows (PowerShell)
.\deploy-sample.ps1

# Windows (Command Prompt)
deploy-sample.bat

# Cross-platform (PowerShell Core)
pwsh ./deploy-sample.ps1
```

### Manual Deployment

1. Navigate to the desired sample folder
2. Initialize azd environment: `azd init`
3. Deploy: `azd up`

## Sample Structure

Each sample includes:
- `azure.yaml` - azd configuration
- `infra/` - Bicep infrastructure templates
- `src/` - Sample application code (where applicable)
- `README.md` - Sample-specific documentation

## Contributing

Feel free to add more samples following the established structure.