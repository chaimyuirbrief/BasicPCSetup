@echo off
:: Batch script to disable IPv6 on Ethernet, Wi-Fi, and Bluetooth Network Connection adapters

:: Check if the script is running with admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    :: Re-run the batch file as admin
    powershell -Command "Start-Process cmd -ArgumentList '/c ""%~f0""' -Verb RunAs"
    exit /b
)

:: Disable IPv6 using PowerShell
powershell -Command ^
    "$adapters = @('Ethernet', 'Wi-Fi', 'Bluetooth Network Connection');" ^
    "foreach ($adapterName in $adapters) {" ^
    "    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $adapterName };" ^
    "    if ($adapter) {" ^
    "        try {" ^
    "            Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Verbose;" ^
    "            Write-Output 'IPv6 has been disabled for the ' + $adapterName + ' adapter.'" ^
    "        } catch {" ^
    "            Write-Output 'Failed to disable IPv6 for the ' + $adapterName + ' adapter. Error: ' + $_;" ^
    "        }" ^
    "    } else {" ^
    "        Write-Output $adapterName + ' adapter not found. Make sure the adapter name is correct.'" ^
    "    }" ^
    "}"
