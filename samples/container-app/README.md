# Container App Sample

This sample demonstrates deploying a containerized application using Azure Container Apps with Azure Developer CLI (azd).

## Architecture

- **Azure Container Apps**: Serverless container hosting platform
- **Azure Container Registry**: Private container registry
- **Azure Container Apps Environment**: Shared environment for container apps
- **Log Analytics Workspace**: Centralized logging and monitoring
- **User-Assigned Managed Identity**: Secure access to Azure resources

## Resources Created

1. Log Analytics Workspace for monitoring and logging
2. Azure Container Registry (Basic tier)
3. User-Assigned Managed Identity with AcrPull permissions
4. Container Apps Environment connected to Log Analytics
5. Container App with auto-scaling and CORS enabled

## Prerequisites

- [Azure Developer CLI (azd)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Docker](https://docs.docker.com/get-docker/) (optional, for building custom images)
- An Azure subscription

## Deployment

### Quick Deploy

From the root of this repository, run:

```bash
# Windows PowerShell
.\deploy-sample.ps1

# Select option 2 for "Container App"
```

### Manual Deploy

1. Navigate to this directory:
   ```bash
   cd samples/container-app
   ```

2. Initialize azd:
   ```bash
   azd init --environment dev
   ```

3. Deploy:
   ```bash
   azd up
   ```

## Configuration

You can customize the deployment by modifying the parameters in `infra/main.parameters.json`:

- `containerImage`: Container image to deploy (default: Microsoft hello world sample)
- `containerCpu`: CPU allocation (0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0)
- `containerMemory`: Memory allocation (0.5Gi, 1Gi, 1.5Gi, 2Gi, 2.5Gi, 3Gi, 3.5Gi, 4Gi)
- `minReplicas`: Minimum number of replicas (0-25)
- `maxReplicas`: Maximum number of replicas (1-25)

## Custom Container Images

To deploy your own container image:

1. Build and push to the created Azure Container Registry:
   ```bash
   # Get the registry login server from deployment outputs
   REGISTRY_SERVER=$(azd env get-values | grep AZURE_CONTAINER_REGISTRY_ENDPOINT | cut -d'=' -f2)
   
   # Build and push your image
   docker build -t $REGISTRY_SERVER/myapp:latest .
   az acr login --name $(echo $REGISTRY_SERVER | cut -d'.' -f1)
   docker push $REGISTRY_SERVER/myapp:latest
   ```

2. Update the `containerImage` parameter to point to your image:
   ```bash
   azd env set CONTAINER_IMAGE "$REGISTRY_SERVER/myapp:latest"
   azd deploy
   ```

## Features

- **Auto-scaling**: Automatically scales based on HTTP requests (up to 10 concurrent requests per instance)
- **CORS Enabled**: Configured to allow cross-origin requests
- **Security**: Uses managed identity for secure access to container registry
- **Monitoring**: Integrated with Log Analytics for comprehensive logging
- **Zero-downtime deployments**: Support for blue-green deployments

## Accessing the Application

After deployment, the application will be available at the URL shown in the deployment output. You can also find it by running:

```bash
azd env get-values | grep CONTAINER_APP_URL
```

## Monitoring and Logs

View logs using:

```bash
# View live logs
azd logs

# Or use Azure CLI
az containerapp logs show --name <container-app-name> --resource-group <resource-group-name> --follow
```

## Security Considerations

- Container registry uses managed identity authentication (no passwords)
- Container app uses user-assigned managed identity
- Network traffic is secured with HTTPS
- Container registry access is limited to Azure services

## Clean Up

To remove all resources:

```bash
azd down
```

## Estimated Costs

With default configuration:
- Container Apps Environment: ~$0/month (consumption-based)
- Container Registry Basic: ~$5/month
- Log Analytics Workspace: Pay-per-GB ingested
- Container App: Pay-per-vCPU-second and memory-GB-second

*Costs may vary by region and actual usage. The consumption-based pricing means you only pay when your app is running.*

## Next Steps

- Add custom domains and SSL certificates
- Implement CI/CD with GitHub Actions
- Add secrets management with Azure Key Vault
- Configure virtual network integration for enhanced security
- Add health checks and custom metrics
