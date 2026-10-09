@echo off
:: Check if the script is running with administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges.
    echo Please run it as an administrator.
    pause
    exit /b
)

:: Run the PowerShell command to enable Microsoft Print to PDF.
:: ONE line on purpose. cmd.exe ends a command at the newline, so a
:: multi-line powershell -Command "..." hands PowerShell an unterminated
:: quote and then tries to run the remaining lines as batch commands --
:: the feature never gets enabled and the trailing pause makes it look
:: like it worked. Enable SMB.bat has always had it on one line.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-WindowsOptionalFeature -Online -FeatureName 'Printing-PrintToPDFServices-Features' -All -NoRestart; Write-Host 'Microsoft Print to PDF has been enabled. Please restart your computer to apply changes.'"
pause
