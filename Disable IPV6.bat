@echo off
setlocal
title Disable IPv6 - All Network Adapters
:: ============================================================================
:: Disable IPv6 - All Network Adapters
::
:: Enumerates EVERY network adapter present on this machine and disables the
:: IPv6 binding on each one. Nothing is hard-coded: the adapter list is
:: discovered at run time, so the script behaves the same on a machine with
:: one adapter or with fifty, whatever they happen to be named.
::
:: Adapters are discovered with:
::     Get-NetAdapterBinding -ComponentID ms_tcpip6
:: which returns one entry per adapter that actually exposes the IPv6 binding
:: -- physical, wireless, Bluetooth, VPN, Hyper-V, USB/dock, loopback, etc.
:: Adapters that are currently down or administratively disabled are included;
:: adapters where IPv6 is already unbound are reported and skipped.
::
:: Scope note: this clears the "Internet Protocol Version 6 (TCP/IPv6)"
:: checkbox per adapter in Network Connections. It deliberately does NOT touch
:: the machine-wide Tcpip6 DisabledComponents registry value, and it does not
:: touch hidden tunnel pseudo-interfaces (Teredo / ISATAP / 6to4), which are
:: not part of the adapter list and do not expose this binding.
:: ============================================================================

:: Check if the script is running with administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 goto :elevate
goto :main

:elevate
echo This script requires administrative privileges. Requesting elevation...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs } catch { exit 1 }"
if errorlevel 1 (
    echo.
    echo Elevation was cancelled or failed.
    echo Right-click this file and choose Run as administrator.
    echo.
    pause
)
exit /b

:main
echo.
echo Disabling IPv6 on every network adapter found on this machine...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "if (-not (Get-Command Get-NetAdapterBinding -ErrorAction SilentlyContinue)) {" ^
  "    Write-Host 'ERROR: The NetAdapter PowerShell cmdlets are not available on this system.' -ForegroundColor Red;" ^
  "    exit 2;" ^
  "};" ^
  "$bindings = @(Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | Sort-Object Name);" ^
  "if ($bindings.Count -eq 0) {" ^
  "    Write-Host 'No network adapters with an IPv6 binding were found.' -ForegroundColor Yellow;" ^
  "    exit 0;" ^
  "};" ^
  "Write-Host ('Found ' + $bindings.Count + ' network adapter(s):');" ^
  "Write-Host '';" ^
  "$disabled = 0; $already = 0; $failed = 0;" ^
  "foreach ($binding in $bindings) {" ^
  "    $label = $binding.Name + ' (' + $binding.InterfaceDescription + ')';" ^
  "    if (-not $binding.Enabled) {" ^
  "        Write-Host ('[ SKIP ] ' + $label + ' - IPv6 already disabled');" ^
  "        $already = $already + 1;" ^
  "        continue;" ^
  "    };" ^
  "    try {" ^
  "        $binding | Disable-NetAdapterBinding -ErrorAction Stop;" ^
  "        Write-Host ('[  OK  ] ' + $label + ' - IPv6 disabled') -ForegroundColor Green;" ^
  "        $disabled = $disabled + 1;" ^
  "    } catch {" ^
  "        Write-Host ('[ FAIL ] ' + $label + ' - ' + $_.Exception.Message) -ForegroundColor Red;" ^
  "        $failed = $failed + 1;" ^
  "    };" ^
  "};" ^
  "Write-Host '';" ^
  "Write-Host ('Adapters processed: ' + $bindings.Count + '   Disabled now: ' + $disabled + '   Already disabled: ' + $already + '   Failed: ' + $failed);" ^
  "$remaining = @(Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | Where-Object { $_.Enabled });" ^
  "if ($remaining.Count -eq 0) {" ^
  "    Write-Host 'Verified: IPv6 is now disabled on every network adapter on this machine.' -ForegroundColor Green;" ^
  "} else {" ^
  "    Write-Host ('Verified: IPv6 is STILL enabled on ' + $remaining.Count + ' adapter(s): ' + (($remaining | ForEach-Object { $_.Name }) -join ', ')) -ForegroundColor Yellow;" ^
  "};" ^
  "if ($failed -gt 0) { exit 1 };" ^
  "exit 0;"

echo.
if errorlevel 2 (
    echo The NetAdapter cmdlets required by this script are not available.
) else if errorlevel 1 (
    echo One or more adapters could not be changed. See the messages above.
) else (
    echo Done.
)
echo.
pause
endlocal
