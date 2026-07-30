@echo off
:: ============================================================================
:: Install WMIC Files
:: Restores the WMIC / WBEM files that Windows removed, by downloading them from
:: the BasicPCSetup repo into C:\Windows\System32\wbem.
::
:: WMIC was removed/deprecated in recent Windows 11 builds. This restores the
:: files needed for WMIC to work again -- much faster than the official DISM
:: Feature-on-Demand install.
::
:: IMPORTANT: This installs ONLY the files that are MISSING from the wbem folder.
:: The core WMI files (wbemcore.dll, wbemprox.dll, etc.) already exist, are owned
:: by TrustedInstaller, and are locked by the running WMI service -- overwriting
:: them would fail with "Access denied" and could break WMI. Windows Update keeps
:: those current, so we intentionally leave them untouched and only fill the gaps.
::
:: The repo files are kept up to date by Publish-WMIC-Files.ps1, which runs on a
:: machine that still has WMIC and receives Windows Updates.
:: ============================================================================

:: Check if the script is running with administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges.
    echo Please run it as an administrator.
    pause
    exit /b
)

echo Restoring missing WMIC files into C:\Windows\System32\wbem ...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$baseUrl = 'https://raw.githubusercontent.com/chaimyuirbrief/BasicPCSetup/main/WMIC%%20files';" ^
  "$dest = Join-Path $env:SystemRoot 'System32\wbem';" ^
  "$files = @('WMIC.exe','WMIC.exe.mui','WMICOOKR.dll','WBEMCons.mof','WbemCons.mfl','wbemcntl.dll','wbemcntl.dll.mui','wbemcons.dll','wbemcore.dll','wbemcore.dll.mui','wbemdisp.dll','wbemdisp.tlb','wbemess.dll','wbemprox.dll','wbemsvc.dll','wbemtest.exe','wbemtest.exe.mui','wmiutils.dll','wmiutils.dll.mui');" ^
  "if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null };" ^
  "$added = 0; $skipped = 0; $failed = 0;" ^
  "foreach ($f in $files) {" ^
  "  $out = Join-Path $dest $f;" ^
  "  if (Test-Path $out) {" ^
  "    Write-Host \"SKIP  $f (already present - leaving system copy)\" -ForegroundColor DarkGray;" ^
  "    $skipped++; continue;" ^
  "  }" ^
  "  $url = \"$baseUrl/$([uri]::EscapeDataString($f))\";" ^
  "  try {" ^
  "    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing;" ^
  "    Write-Host \"ADD   $f\" -ForegroundColor Green;" ^
  "    $added++;" ^
  "  } catch {" ^
  "    Write-Warning \"FAIL  $f : $($_.Exception.Message)\";" ^
  "    $failed++;" ^
  "  }" ^
  "};" ^
  "Write-Host '';" ^
  "Write-Host \"Done. Added $added, skipped $skipped (already present), failed $failed.\" -ForegroundColor Cyan;" ^
  "if ($added -gt 0) { Write-Host 'WMIC files restored to' $dest -ForegroundColor Green };"

echo.
echo Files marked SKIP already existed and were left as-is (Windows keeps those
echo current). Only missing files are added, so you should not see access-denied
echo errors. If a file shows FAIL, re-run this as administrator.
echo.
pause
