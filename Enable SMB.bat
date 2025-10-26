@echo off
:: Check if the script is running with administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges.
    echo Please run it as an administrator.
    pause
    exit /b
)

:: Run the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-WindowsOptionalFeature -Online -FeatureName 'SMB1Protocol' -All -NoRestart; Write-Host 'SMB 1.0/CIFS File Sharing Support has been enabled. Please restart your computer to apply changes.'"
pause
