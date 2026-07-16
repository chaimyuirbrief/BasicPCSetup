@echo off
:: ============================================================================
:: Install WMIC Files
:: Downloads the WMIC / WBEM files from the BasicPCSetup repo and copies them
:: into C:\Windows\System32\wbem.
::
:: WMIC was removed/deprecated in recent Windows 11 builds. This restores the
:: files needed for WMIC and the WBEM tools to work again -- much faster than
:: the official DISM Feature-on-Demand install.
::
:: The files in the repo are kept up to date by Publish-WMIC-Files.ps1, which
:: runs on a machine that still has WMIC and receives Windows Updates, so the
:: files installed here stay current without any manual copying.
:: ============================================================================

:: Check if the script is running with administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges.
    echo Please run it as an administrator.
    pause
    exit /b
)

echo Downloading WMIC files from GitHub and installing to C:\Windows\System32\wbem ...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$baseUrl = 'https://raw.githubusercontent.com/chaimyuirbrief/BasicPCSetup/main/WMIC%%20files';" ^
  "$dest = Join-Path $env:SystemRoot 'System32\wbem';" ^
  "$files = @('WMIC.exe','WMIC.exe.mui','WMICOOKR.dll','WBEMCons.mof','WbemCons.mfl','wbemcntl.dll','wbemcntl.dll.mui','wbemcons.dll','wbemcore.dll','wbemcore.dll.mui','wbemdisp.dll','wbemdisp.tlb','wbemess.dll','wbemprox.dll','wbemsvc.dll','wbemtest.exe','wbemtest.exe.mui','wmiutils.dll','wmiutils.dll.mui');" ^
  "if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null };" ^
  "foreach ($f in $files) {" ^
  "  $url = \"$baseUrl/$([uri]::EscapeDataString($f))\";" ^
  "  $out = Join-Path $dest $f;" ^
  "  try {" ^
  "    Write-Host \"Downloading $f ...\";" ^
  "    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing;" ^
  "  } catch {" ^
  "    Write-Warning \"Failed to install $f : $($_.Exception.Message)\";" ^
  "  }" ^
  "};" ^
  "Write-Host '';" ^
  "Write-Host 'Done. WMIC files have been installed to' $dest -ForegroundColor Green;"

echo.
echo If you see any warnings above, the corresponding file could not be
echo downloaded or replaced (it may be in use). Re-run as administrator.
echo.
pause
