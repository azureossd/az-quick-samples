#!/bin/bash

# Azure Quick Samples Deployment Script
# This script helps you select and deploy Azure sample projects using azd

# Function to display colored output
print_success() { echo -e "\033[32m$1\033[0m"; }
print_warning() { echo -e "\033[33m$1\033[0m"; }
print_error() { echo -e "\033[31m$1\033[0m"; }
print_info() { echo -e "\033[36m$1\033[0m"; }

# Default values
SAMPLE_NAME=""
ENVIRONMENT_NAME=""
SKIP_PROMPTS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--sample)
            SAMPLE_NAME="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT_NAME="$2"
            shift 2
            ;;
        --skip-prompts)
            SKIP_PROMPTS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -s, --sample NAME        Sample name to deploy"
            echo "  -e, --environment NAME   Environment name (default: dev)"
            echo "  --skip-prompts          Skip interactive prompts"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Sample definitions
declare -a samples=(
    "webapp-database|Web App + SQL Database|Simple web application with Azure SQL Database and App Service|samples/webapp-database"
    "container-app|Container App|Containerized application using Azure Container Apps|samples/container-app"
    "fastapi-webapp|FastAPI Web App|Python FastAPI application with RESTful API and App Service Linux|samples/fastapi-webapp"
    "function-storage|Function App + Storage|Azure Functions with Blob Storage and monitoring|samples/function-storage"
    "static-web-app|Static Web App|Frontend application with Azure Static Web Apps|samples/static-web-app"
    "api-cache|API + Redis Cache|REST API with Azure Cache for Redis|samples/api-cache"
    "ai-chat-app|AI Chat Application|Chat application with Azure OpenAI Service|samples/ai-chat-app"
)

print_info "=== Azure Quick Samples Deployment Tool ==="
print_info ""

# Check if azd is installed
if ! command -v azd &> /dev/null; then
    print_error "✗ Azure Developer CLI (azd) is not installed or not in PATH"
    print_info "Please install azd from: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd"
    exit 1
else
    print_success "✓ Azure Developer CLI found"
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "✗ Azure CLI (az) is not installed or not in PATH"
    print_info "Please install Azure CLI from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
else
    print_success "✓ Azure CLI found"
fi

# Sample selection
if [[ -z "$SAMPLE_NAME" && "$SKIP_PROMPTS" == false ]]; then
    print_info ""
    print_info "Available samples:"
    print_info ""
    
    for i in "${!samples[@]}"; do
        IFS='|' read -ra SAMPLE <<< "${samples[$i]}"
        echo "[$((i + 1))] ${SAMPLE[1]}"
        echo "    ${SAMPLE[2]}"
        echo ""
    done
    
    while true; do
        read -p "Select a sample (1-${#samples[@]}): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#samples[@]}" ]; then
            selected_index=$((selection - 1))
            break
        else
            print_error "Please enter a number between 1 and ${#samples[@]}"
        fi
    done
    
    IFS='|' read -ra SELECTED_SAMPLE <<< "${samples[$selected_index]}"
elif [[ -n "$SAMPLE_NAME" ]]; then
    found=false
    for sample in "${samples[@]}"; do
        IFS='|' read -ra SAMPLE <<< "$sample"
        if [[ "${SAMPLE[0]}" == "$SAMPLE_NAME" ]]; then
            SELECTED_SAMPLE=("${SAMPLE[@]}")
            found=true
            break
        fi
    done
    
    if [[ "$found" == false ]]; then
        print_error "Sample '$SAMPLE_NAME' not found"
        available_samples=""
        for sample in "${samples[@]}"; do
            IFS='|' read -ra SAMPLE <<< "$sample"
            available_samples+="${SAMPLE[0]}, "
        done
        print_info "Available samples: ${available_samples%, }"
        exit 1
    fi
else
    print_error "Sample name is required when using --skip-prompts"
    exit 1
fi

print_success ""
print_success "Selected: ${SELECTED_SAMPLE[1]}"
print_success "Description: ${SELECTED_SAMPLE[2]}"

# Environment name
if [[ -z "$ENVIRONMENT_NAME" && "$SKIP_PROMPTS" == false ]]; then
    print_info ""
    read -p "Enter environment name (or press Enter for default 'dev'): " ENVIRONMENT_NAME
    if [[ -z "$ENVIRONMENT_NAME" ]]; then
        ENVIRONMENT_NAME="dev"
    fi
elif [[ -z "$ENVIRONMENT_NAME" ]]; then
    ENVIRONMENT_NAME="dev"
fi

print_info ""
print_info "Environment: $ENVIRONMENT_NAME"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_PATH="$SCRIPT_DIR/${SELECTED_SAMPLE[3]}"

# Check if sample directory exists
if [[ ! -d "$SAMPLE_PATH" ]]; then
    print_error "Sample directory not found: $SAMPLE_PATH"
    print_info "The sample may not be created yet. Please check the repository."
    exit 1
fi

# Change to sample directory
print_info ""
print_info "Changing to sample directory: $SAMPLE_PATH"
cd "$SAMPLE_PATH" || exit 1

# Check if already initialized
AZD_CONFIG_PATH="$SAMPLE_PATH/.azure"
if [[ -d "$AZD_CONFIG_PATH" ]]; then
    print_warning "Sample appears to be already initialized."
    if [[ "$SKIP_PROMPTS" == false ]]; then
        read -p "Do you want to reinitialize? (y/N): " reinit
        if [[ "$reinit" == "y" || "$reinit" == "Y" ]]; then
            rm -rf "$AZD_CONFIG_PATH"
            print_info "Cleaned up existing azd configuration"
        fi
    fi
fi

# Initialize azd if needed
if [[ ! -d "$AZD_CONFIG_PATH" ]]; then
    print_info ""
    print_info "Initializing Azure Developer CLI..."
    if ! azd init --environment "$ENVIRONMENT_NAME"; then
        print_error "azd init failed"
        exit 1
    fi
    print_success "✓ azd initialized"
fi

# Deploy the sample
print_info ""
print_info "Deploying sample..."
print_warning "This will create Azure resources and may incur costs."

if [[ "$SKIP_PROMPTS" == false ]]; then
    read -p "Continue with deployment? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
fi

print_info ""
print_info "Running 'azd up'..."
if azd up; then
    print_success ""
    print_success "🎉 Deployment completed successfully!"
    print_info ""
    print_info "You can now:"
    print_info "- View your resources in the Azure portal"
    print_info "- Check logs with: azd logs"
    print_info "- Update and redeploy with: azd deploy"
    print_info "- Clean up resources with: azd down"
else
    print_error "Deployment failed. Check the output above for details."
    exit 1
fi

print_info ""
print_info "Deployment script completed."