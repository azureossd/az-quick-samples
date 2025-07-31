@echo off
setlocal enabledelayedexpansion

echo === Azure Quick Samples Deployment Tool ===
echo.

:: Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell is required but not found.
    echo Please install PowerShell and try again.
    exit /b 1
)

:: Check if azd is installed
azd version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Azure Developer CLI (azd) is not installed or not in PATH
    echo Please install azd from: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd
    exit /b 1
)

:: Check if Azure CLI is installed
az version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Azure CLI (az) is not installed or not in PATH
    echo Please install Azure CLI from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
    exit /b 1
)

echo Running PowerShell deployment script...
echo.

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0deploy-sample.ps1" %*

echo.
echo Batch script completed.
pause
