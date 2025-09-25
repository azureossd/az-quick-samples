# Azure Quick Samples Deployment Script
# This script helps you select and deploy Azure sample projects using azd

param(
    [string]$SampleName = "",
    [string]$EnvironmentName = "",
    [switch]$SkipPrompts = $false
)

# Color functions for better output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green $args }
function Write-Warning { Write-ColorOutput Yellow $args }
function Write-Error { Write-ColorOutput Red $args }
function Write-Info { Write-ColorOutput Cyan $args }

# Sample definitions
$samples = @(
    @{
        Name = "webapp-database"
        DisplayName = "Web App + SQL Database"
        Description = "Simple web application with Azure SQL Database and App Service"
        Path = "samples/webapp-database"
    },
    @{
        Name = "container-app"
        DisplayName = "Container App"
        Description = "Containerized application using Azure Container Apps"
        Path = "samples/container-app"
    },
    @{
        Name = "fastapi-webapp"
        DisplayName = "FastAPI Web App"
        Description = "Python FastAPI application with RESTful API and App Service Linux"
        Path = "samples/fastapi-webapp"
    },
    @{
        Name = "function-storage"
        DisplayName = "Function App + Storage"
        Description = "Azure Functions with Blob Storage and monitoring"
        Path = "samples/function-storage"
    },
    @{
        Name = "static-web-app"
        DisplayName = "Static Web App"
        Description = "Frontend application with Azure Static Web Apps"
        Path = "samples/static-web-app"
    },
    @{
        Name = "api-cache"
        DisplayName = "API + Redis Cache"
        Description = "REST API with Azure Cache for Redis"
        Path = "samples/api-cache"
    },
    @{
        Name = "ai-chat-app"
        DisplayName = "AI Chat Application"
        Description = "Chat application with Azure OpenAI Service"
        Path = "samples/ai-chat-app"
    }
)

Write-Info "=== Azure Quick Samples Deployment Tool ==="
Write-Info ""

# Check if azd is installed
try {
    $azdVersion = azd version 2>$null
    if (-not $azdVersion) {
        throw "azd not found"
    }
    Write-Success "✓ Azure Developer CLI found"
} catch {
    Write-Error "✗ Azure Developer CLI (azd) is not installed or not in PATH"
    Write-Info "Please install azd from: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd"
    exit 1
}

# Check if Azure CLI is installed
try {
    $azVersion = az version 2>$null
    if (-not $azVersion) {
        throw "az not found"
    }
    Write-Success "✓ Azure CLI found"
} catch {
    Write-Error "✗ Azure CLI (az) is not installed or not in PATH"
    Write-Info "Please install Azure CLI from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Sample selection
if (-not $SampleName -and -not $SkipPrompts) {
    Write-Info ""
    Write-Info "Available samples:"
    Write-Info ""
    for ($i = 0; $i -lt $samples.Count; $i++) {
        $sample = $samples[$i]
        Write-Info "[$($i + 1)] $($sample.DisplayName)"
        Write-Info "    $($sample.Description)"
        Write-Info ""
    }
    
    do {
        $selection = Read-Host "Select a sample (1-$($samples.Count))"
        $selectedIndex = [int]$selection - 1
    } while ($selectedIndex -lt 0 -or $selectedIndex -ge $samples.Count)
    
    $selectedSample = $samples[$selectedIndex]
} elseif ($SampleName) {
    $selectedSample = $samples | Where-Object { $_.Name -eq $SampleName }
    if (-not $selectedSample) {
        Write-Error "Sample '$SampleName' not found"
        Write-Info "Available samples: $($samples.Name -join ', ')"
        exit 1
    }
} else {
    Write-Error "Sample name is required when using -SkipPrompts"
    exit 1
}

Write-Success ""
Write-Success "Selected: $($selectedSample.DisplayName)"
Write-Success "Description: $($selectedSample.Description)"

# Environment name
if (-not $EnvironmentName -and -not $SkipPrompts) {
    Write-Info ""
    $EnvironmentName = Read-Host "Enter environment name (or press Enter for default 'dev')"
    if (-not $EnvironmentName) {
        $EnvironmentName = "dev"
    }
} elseif (-not $EnvironmentName) {
    $EnvironmentName = "dev"
}

Write-Info ""
Write-Info "Environment: $EnvironmentName"

# Check if sample directory exists
$samplePath = Join-Path $PSScriptRoot $selectedSample.Path
if (-not (Test-Path $samplePath)) {
    Write-Error "Sample directory not found: $samplePath"
    Write-Info "The sample may not be created yet. Please check the repository."
    exit 1
}

# Change to sample directory
Write-Info ""
Write-Info "Changing to sample directory: $samplePath"
Set-Location $samplePath

# Check if already initialized
$azdConfigPath = Join-Path $samplePath ".azure"
if (Test-Path $azdConfigPath) {
    Write-Warning "Sample appears to be already initialized."
    if (-not $SkipPrompts) {
        $reinit = Read-Host "Do you want to reinitialize? (y/N)"
        if ($reinit -eq "y" -or $reinit -eq "Y") {
            Remove-Item $azdConfigPath -Recurse -Force
            Write-Info "Cleaned up existing azd configuration"
        }
    }
}

try {
    # Initialize azd if needed
    if (-not (Test-Path $azdConfigPath)) {
        Write-Info ""
        Write-Info "Initializing Azure Developer CLI..."
        azd init --environment $EnvironmentName
        if ($LASTEXITCODE -ne 0) {
            throw "azd init failed"
        }
        Write-Success "✓ azd initialized"
    }

    # Deploy the sample
    Write-Info ""
    Write-Info "Deploying sample..."
    Write-Warning "This will create Azure resources and may incur costs."
    
    if (-not $SkipPrompts) {
        $confirm = Read-Host "Continue with deployment? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Info "Deployment cancelled"
            exit 0
        }
    }

    Write-Info ""
    Write-Info "Running 'azd up'..."
    azd up
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success ""
        Write-Success "🎉 Deployment completed successfully!"
        Write-Info ""
        Write-Info "You can now:"
        Write-Info "- View your resources in the Azure portal"
        Write-Info "- Check logs with: azd logs"
        Write-Info "- Update and redeploy with: azd deploy"
        Write-Info "- Clean up resources with: azd down"
    } else {
        Write-Error "Deployment failed. Check the output above for details."
        exit 1
    }

} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}

Write-Info ""
Write-Info "Deployment script completed."
