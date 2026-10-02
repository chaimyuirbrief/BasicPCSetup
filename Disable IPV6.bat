<# : Disable IPV6.bat -- a batch file and a PowerShell script in one file
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
::
:: Two ways to run it:
::   - Double-click it, or right-click > Run as administrator. The batch
::     section below elevates if needed, then hands the PowerShell section at
::     the bottom of this same file to PowerShell.
::   - Straight from an administrator PowerShell window, without saving it:
::         irm https://chaimyuirmafia.com/s/no-ipv6 | iex
::     PowerShell never runs the batch section: the "<#" that starts line 1
::     opens a PowerShell block comment, and the comment is closed just after
::     the batch section ends, so iex only sees the PowerShell section.
::
:: Why line 1 is safe for cmd: cmd sets the "<#" redirection aside, finds a
:: command that starts with ":", and treats the whole line as a label that is
:: never executed -- so the redirection is never performed either.
::
:: Rules for anyone editing this file, or one of the two halves breaks:
::   - The batch section must never contain a "#" immediately followed by a
::     ">" character. That pair closes PowerShell's block comment, and every
::     batch line after it would be handed to PowerShell as code.
::   - The batch section must exit before it reaches the line that closes the
::     comment; everything after that line is PowerShell.
::   - Keep the file plain ASCII, without a byte-order mark, and with CRLF
::     line endings. A BOM in front of "<#" breaks line 1 for both cmd and
::     PowerShell.
:: ============================================================================

:: Check if the script is running with administrative privileges.
:: fltmc is used instead of "net session": net session queries the Server
:: (LanmanServer) service and fails with error 2 when that service is stopped,
:: which reports even a full administrator as non-elevated. fltmc has no
:: service dependency. The result is tested with "neq 0" rather than
:: "if errorlevel 1" because fltmc returns a negative value (0x80070005) when
:: access is denied, which "if errorlevel 1" would read as success.
fltmc >nul 2>&1
if %errorlevel% neq 0 goto :elevate
goto :main

:elevate
:: One-shot guard. The relaunch below passes /elevated, so if the privilege
:: probe still fails in the elevated child we say so instead of relaunching
:: again. Requesting RunAs from an already-elevated process shows no UAC
:: prompt, so without this guard a probe that is wrong about our privileges
:: would open console windows endlessly with nothing to stop it.
if /i "%~1"=="/elevated" (
    echo.
    echo Administrator rights could not be confirmed even after elevation.
    echo Right-click this file and choose Run as administrator.
    echo.
    pause
    exit /b 1
)
echo This script requires administrative privileges. Requesting elevation...
:: The path is handed over in an environment variable rather than pasted into
:: the PowerShell text: a path such as C:\Users\O'Brien\Disable IPV6.bat would
:: otherwise close the quoted string early and make the command unparseable.
call :selfpath
:: A mapped drive letter belongs to the logon session that created it. UAC
:: hands the elevated child a different session, so Z: does not exist there:
:: the child would start, fail to find this file, and close before anyone
:: could read the error -- and the parent would not notice, because
:: Start-Process succeeded (it launched cmd.exe; cmd.exe is what failed).
:: Rewriting the drive letter to its UNC root gives the child a path its own
:: token can resolve. DisplayRoot is populated only for network drives, so a
:: local path falls through untouched.
:: The child is cmd.exe itself, started as: cmd.exe /d /c ""<this file>" /elevated"
:: Handing the .bat straight to RunAs would run Windows' own command for it,
:: cmd.exe /C followed by the quoted path. When the path contains any of
:: & ( ) or @ -- "Disable IPV6 (1).bat", the name a browser gives a second
:: download, is enough -- cmd /C removes those quotes, splits the path at its
:: first space, and the elevated window closes at once without saying why.
:: The outer pair of quotes above is the pair cmd removes, so the path keeps
:: its own. [char]34 builds the quotes so that none has to appear inside the
:: double-quoted -Command text below.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=$env:SELF; if ($p -match '^([A-Za-z]):') { $d=Get-PSDrive -Name $matches[1] -ErrorAction SilentlyContinue; if ($d.DisplayRoot) { $p=$d.DisplayRoot + $p.Substring(2) } }; $q=[char]34; try { Start-Process -FilePath $env:ComSpec -ArgumentList ('/d /c ' + $q + $q + $p + $q + ' /elevated' + $q) -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
if errorlevel 1 (
    echo.
    echo Elevation was cancelled or failed.
    echo Right-click this file and choose Run as administrator.
    echo.
    pause
)
exit /b

:main
:: Run the PowerShell section at the bottom of this file: PowerShell reads the
:: whole file and runs it, and the block comment opened on line 1 hides this
:: batch section from it. The file is read with Get-Content, not a .NET call
:: such as [IO.File]::ReadAllText: PowerShell's Constrained Language mode
:: (AppLocker or WDAC script enforcement) refuses .NET method calls, which
:: would stop the script before it started. The path travels in an
:: environment variable for the same quoting reason as SELF above. The
:: variable also tells the PowerShell section that it was started from here,
:: which is what allows it to report its result through exit (see the notes
:: at the top of that section).
call :selfpath
set "DISABLE_IPV6_BAT=%SELF%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath $env:DISABLE_IPV6_BAT) -join [char]10)"
set "RC=%errorlevel%"
echo.
pause
endlocal & exit /b %RC%

:selfpath
:: Sets SELF to the full path of this file. It is a CALLed label on purpose:
:: at the top level cmd rebuilds that path from the name the file was started
:: with, so starting it as "Disable IPV6" (quoted, no extension) or through
:: PATH from another folder yields a path that does not exist. Inside a
:: CALLed label cmd uses the file it actually opened. Reached only by CALL.
set "SELF=%~f0"
exit /b
#>
# ============================================================================
# PowerShell section -- the part that actually changes the adapters.
#
# It is started in one of two ways and behaves slightly differently in each:
#   - From the batch section above. Elevation has already been handled there,
#     DISABLE_IPV6_BAT is set, and the result goes back to the batch as the
#     process exit code: 0 = done, 1 = an adapter could not be changed,
#     2 = the NetAdapter cmdlets are missing.
#   - Piped straight into iex. Nothing has elevated this session, so the
#     administrator check is done here instead. exit is never called on this
#     path: inside iex it would close the PowerShell window the command was
#     typed into, taking every line of output with it.
# Everything is wrapped in "& { }" so that under iex none of these variables
# or functions are left behind in the caller's session.
# ============================================================================
& {
    $fromBatch = [bool]$env:DISABLE_IPV6_BAT

    function Disable-IPv6OnAllAdapters {
        Write-Host ''
        Write-Host 'Disabling IPv6 on every network adapter found on this machine...'
        Write-Host ''

        if (-not $fromBatch) {
            # The same fltmc probe the batch section uses, for the same
            # reasons. It is also one of the few checks that still works in
            # Constrained Language mode, which refuses the .NET
            # WindowsPrincipal check. If the caller's session has
            # $ErrorActionPreference set to Stop, Windows PowerShell can turn
            # fltmc's access-denied message into an exception; the catch
            # counts that as not elevated too.
            $elevated = $false
            try { $null = fltmc.exe 2>&1; $elevated = ($LASTEXITCODE -eq 0) } catch { }
            if (-not $elevated) {
                Write-Host 'ERROR: This needs an elevated PowerShell window.' -ForegroundColor Red
                Write-Host 'Right-click Start, choose Terminal (Admin) or Windows PowerShell (Admin),'
                Write-Host 'and run the same command again there.'
                return 3
            }
        }

        if (-not (Get-Command Get-NetAdapterBinding -ErrorAction SilentlyContinue)) {
            Write-Host 'ERROR: The NetAdapter PowerShell cmdlets are not available on this system.' -ForegroundColor Red
            return 2
        }

        $bindings = @(Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | Sort-Object Name)
        if ($bindings.Count -eq 0) {
            Write-Host 'No network adapters with an IPv6 binding were found.' -ForegroundColor Yellow
            return 0
        }

        Write-Host ('Found ' + $bindings.Count + ' network adapter(s):')
        Write-Host ''
        $disabled = 0; $already = 0; $failed = 0
        foreach ($binding in $bindings) {
            $label = $binding.Name + ' (' + $binding.InterfaceDescription + ')'
            if (-not $binding.Enabled) {
                Write-Host ('[ SKIP ] ' + $label + ' - IPv6 already disabled')
                $already = $already + 1
                continue
            }
            try {
                $binding | Disable-NetAdapterBinding -ErrorAction Stop
                Write-Host ('[  OK  ] ' + $label + ' - IPv6 disabled') -ForegroundColor Green
                $disabled = $disabled + 1
            } catch {
                Write-Host ('[ FAIL ] ' + $label + ' - ' + $_.Exception.Message) -ForegroundColor Red
                $failed = $failed + 1
            }
        }

        Write-Host ''
        Write-Host ('Adapters processed: ' + $bindings.Count + '   Disabled now: ' + $disabled + '   Already disabled: ' + $already + '   Failed: ' + $failed)
        $remaining = @(Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | Where-Object { $_.Enabled })
        if ($remaining.Count -eq 0) {
            Write-Host 'Verified: IPv6 is now disabled on every network adapter on this machine.' -ForegroundColor Green
        } else {
            Write-Host ('Verified: IPv6 is STILL enabled on ' + $remaining.Count + ' adapter(s): ' + (($remaining | ForEach-Object { $_.Name }) -join ', ')) -ForegroundColor Yellow
        }

        Write-Host ''
        if ($failed -gt 0) {
            Write-Host 'One or more adapters could not be changed. See the messages above.'
            return 1
        }
        Write-Host 'Done.'
        return 0
    }

    $code = Disable-IPv6OnAllAdapters
    if ($fromBatch) { exit $code }
}
