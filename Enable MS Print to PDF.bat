@echo off
:: Check if the script is running with administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges.
    echo Please run it as an administrator.
    pause
    exit /b
)

:: Run the PowerShell command to enable Microsoft Print to PDF
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
    if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command `"Enable-WindowsOptionalFeature -Online -FeatureName `\"Printing-PrintToPDFServices-Features`\" -All -NoRestart; Write-Output `"Microsoft Print to PDF has been enabled. Please restart your computer to apply changes.`"; pause`"'
        exit
    } else {
        Enable-WindowsOptionalFeature -Online -FeatureName 'Printing-PrintToPDFServices-Features' -All -NoRestart
        Write-Output 'Microsoft Print to PDF has been enabled. Please restart your computer to apply changes.'
        pause
    }
}"
pause
