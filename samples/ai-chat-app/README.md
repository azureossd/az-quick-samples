# AI Chat App Sample

This sample demonstrates how to create a chat application using Azure OpenAI Service with Azure Developer CLI (azd).

## Architecture

This sample creates:
- **Azure OpenAI Service**: Provides GPT-3.5 Turbo model for conversational AI
- **App Service**: Hosts the Python Flask chat application
- **Model Deployment**: Deploys GPT-3.5 Turbo model to the OpenAI service

## Prerequisites

Before deploying this sample, ensure you have:

1. **Azure CLI** installed and logged in
2. **Azure Developer CLI (azd)** installed
3. **Access to Azure OpenAI Service** in your subscription
4. An **Azure subscription** with appropriate permissions
5. **Python 3.11** (for local development)

## Deployment

### Quick Deploy with azd

1. Navigate to this sample directory:
   ```cmd
   cd samples\ai-chat-app
   ```

2. Initialize azd (if not already done):
   ```cmd
   azd init
   ```

3. Deploy the infrastructure and application:
   ```cmd
   azd up
   ```

### Manual Steps

If you prefer to deploy manually:

1. **Provision Infrastructure**:
   ```cmd
   azd provision
   ```

2. **Deploy Application**:
   ```cmd
   azd deploy
   ```

## Configuration

The application uses these environment variables (automatically configured during deployment):

- `AZURE_OPENAI_ENDPOINT`: The OpenAI service endpoint
- `AZURE_OPENAI_API_KEY`: API key for accessing the OpenAI service
- `AZURE_OPENAI_DEPLOYMENT_NAME`: Name of the deployed model
- `AZURE_OPENAI_MODEL_NAME`: The model name (gpt-35-turbo)
- `AZURE_OPENAI_API_VERSION`: API version for OpenAI calls

## Customization

### OpenAI Model Configuration

You can customize the AI model by modifying `infra/main.parameters.json`:

```json
{
  "modelDeploymentName": {
    "value": "gpt-4"
  },
  "modelName": {
    "value": "gpt-4"
  },
  "modelVersion": {
    "value": "0613"
  }
}
```

### App Service Plan

Change the App Service Plan SKU in `infra/main.parameters.json`:

```json
{
  "appServicePlanSku": {
    "value": "S1"
  }
}
```

Available SKUs: B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2

## Application Structure

```
ai-chat-app/
├── azure.yaml           # Azure Developer CLI configuration
├── infra/              # Infrastructure as Code (Bicep)
│   ├── main.bicep      # Main infrastructure template
│   └── main.parameters.json # Parameters file
├── src/                # Application source code
│   ├── app.py         # Flask application
│   ├── requirements.txt # Python dependencies
│   └── templates/     # HTML templates
│       └── index.html # Chat interface
└── README.md          # This file
```

## Local Development

1. **Install dependencies**:
   ```cmd
   cd src
   pip install -r requirements.txt
   ```

2. **Set environment variables**:
   ```cmd
   set AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com/
   set AZURE_OPENAI_API_KEY=your-api-key
   set AZURE_OPENAI_DEPLOYMENT_NAME=gpt-35-turbo
   set AZURE_OPENAI_MODEL_NAME=gpt-35-turbo
   set AZURE_OPENAI_API_VERSION=2024-06-01
   ```

3. **Run the application**:
   ```cmd
   python app.py
   ```

4. **Open browser** to `http://localhost:5000`

## Features

- **Real-time Chat**: Interactive chat interface with Azure OpenAI
- **Conversation History**: Maintains chat context during the session
- **Responsive Design**: Works on desktop and mobile devices
- **Error Handling**: Graceful handling of API errors and timeouts
- **Secure Configuration**: API keys managed through App Service settings

## Monitoring and Troubleshooting

### View Application Logs

```cmd
azd logs
```

### Monitor OpenAI Usage

Check your OpenAI service usage in the Azure portal:
1. Navigate to your OpenAI resource
2. Go to "Metrics" to view token usage and request counts
3. Check "Diagnostics settings" for detailed logging

### Common Issues

1. **OpenAI Service Access**: Ensure your subscription has access to Azure OpenAI Service
2. **Model Availability**: GPT-3.5 Turbo might not be available in all regions
3. **Quota Limits**: Check your OpenAI service quotas if requests are failing

## Cost Considerations

- **App Service**: Charges based on the selected SKU
- **Azure OpenAI**: Pay-per-token pricing for API calls
- **Model Deployment**: Standard deployment costs for hosting the model

Estimated monthly cost for B1 App Service Plan with moderate usage: $15-30

## Security

- HTTPS enforced for all connections
- API keys stored securely in App Service configuration
- CORS configured for web application access
- Minimum TLS version set to 1.2

## Next Steps

- Implement user authentication for multi-user support
- Add conversation persistence with Azure Cosmos DB
- Integrate with Azure Active Directory for enterprise scenarios
- Add custom prompt engineering for domain-specific responses
- Implement rate limiting and usage monitoring

## Resources

- [Azure OpenAI Service Documentation](https://docs.microsoft.com/azure/cognitive-services/openai/)
- [Azure Developer CLI Documentation](https://docs.microsoft.com/azure/developer-cli/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
