# FastAPI Web App Sample

This sample demonstrates how to deploy a Python FastAPI application to Azure App Service on Linux using the Azure Developer CLI (azd).

## Overview

This sample includes:
- **FastAPI application** with REST API endpoints
- **Azure App Service on Linux** with Python 3.11 runtime
- **Health check endpoint** for monitoring
- **CORS support** for web applications
- **Interactive API documentation** with Swagger UI
- **Infrastructure as Code** using Bicep templates

## Features

- ✅ RESTful API with CRUD operations
- ✅ Interactive API documentation (`/docs`)
- ✅ Health check endpoint (`/health`)
- ✅ Environment-based configuration
- ✅ Request/response validation with Pydantic
- ✅ Error handling and logging
- ✅ CORS middleware for web integration

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Root endpoint with API information |
| GET | `/health` | Health check endpoint |
| GET | `/items` | Get all items |
| GET | `/items/{id}` | Get item by ID |
| POST | `/items` | Create a new item |
| PUT | `/items/{id}` | Update an existing item |
| DELETE | `/items/{id}` | Delete an item |
| GET | `/info` | Get application information |
| GET | `/docs` | Interactive API documentation (Swagger UI) |
| GET | `/redoc` | Alternative API documentation (ReDoc) |

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Azure Developer CLI (azd)](https://docs.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Python 3.11+](https://www.python.org/downloads/)
- Azure subscription

## Local Development

1. **Clone the repository and navigate to this sample:**
   ```bash
   cd samples/fastapi-webapp
   ```

2. **Create a virtual environment:**
   ```bash
   python -m venv venv
   ```

3. **Activate the virtual environment:**
   ```bash
   # Windows
   venv\Scripts\activate
   
   # macOS/Linux
   source venv/bin/activate
   ```

4. **Install dependencies:**
   ```bash
   pip install -r src/requirements.txt
   ```

5. **Run the application locally:**
   ```bash
   cd src
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **Open your browser and navigate to:**
   - Application: http://localhost:8000
   - API Documentation: http://localhost:8000/docs
   - Health Check: http://localhost:8000/health

## Deployment to Azure

1. **Initialize the Azure Developer CLI:**
   ```bash
   azd init
   ```

2. **Login to Azure:**
   ```bash
   azd auth login
   ```

3. **Deploy to Azure:**
   ```bash
   azd up
   ```

   This command will:
   - Provision the Azure resources (App Service Plan, App Service)
   - Build and deploy your FastAPI application
   - Configure the application settings

4. **Access your deployed application:**
   After deployment, azd will display the URL of your deployed application.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐
│                 │    │                  │
│   User/Client   │───▶│   Azure App      │
│                 │    │   Service        │
└─────────────────┘    │   (Linux)        │
                       │                  │
                       │  FastAPI App     │
                       │  Python 3.11     │
                       └──────────────────┘
```

### Azure Resources

- **Resource Group**: Container for all resources
- **App Service Plan**: Linux-based hosting plan
- **App Service**: Web application hosting the FastAPI app

## Configuration

The application uses environment variables for configuration:

- `ENVIRONMENT`: Application environment (development/production)
- `PYTHONPATH`: Python module search path
- `PORT`: Port number for the application (set automatically by Azure)

## Sample Data

The application includes sample data for demonstration:
- Items with ID, name, description, price, and creation timestamp
- In-memory storage (data will reset on app restart)

## Testing the API

You can test the API using:

1. **Interactive documentation**: Visit `/docs` endpoint
2. **curl commands**:
   ```bash
   # Get all items
   curl https://your-app.azurewebsites.net/items
   
   # Create a new item
   curl -X POST https://your-app.azurewebsites.net/items \
        -H "Content-Type: application/json" \
        -d '{"name": "New Item", "description": "A new item", "price": 19.99}'
   
   # Get health status
   curl https://your-app.azurewebsites.net/health
   ```

3. **Python requests**:
   ```python
   import requests
   
   # Get all items
   response = requests.get("https://your-app.azurewebsites.net/items")
   print(response.json())
   ```

## Troubleshooting

1. **Check application logs:**
   ```bash
   azd monitor --live
   ```

2. **Verify deployment status:**
   ```bash
   azd show
   ```

3. **Common issues:**
   - Ensure Python 3.11 is specified in the Bicep template
   - Check that all required dependencies are in requirements.txt
   - Verify the startup command in App Service configuration

## Clean Up

To delete all Azure resources created by this sample:

```bash
azd down
```

## Learn More

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure Developer CLI Documentation](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
- [Python on Azure App Service](https://docs.microsoft.com/azure/app-service/quickstart-python)
