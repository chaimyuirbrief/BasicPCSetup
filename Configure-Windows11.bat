@echo off
setlocal EnableExtensions

rem ============================================================
rem  Windows 11 GUI-equivalent configuration script
rem  Applies: taskbar (left align, no widgets, End task),
rem  date/time (auto tz, auto time, tray clock, seconds,
rem  Israel additional clock, notification-center clock,
rem  NTP server time.nist.gov + sync), clipboard history,
rem  and adds Hebrew language with all optional FoD features
rem  (without changing the display language).
rem
rem  NOTE: HKCU writes apply to whatever user runs this script.
rem  Run it as the signed-in user with an account that has
rem  admin rights, so UAC elevates in-place. If you elevate
rem  using a DIFFERENT admin account, the per-user settings
rem  will land in that admin's profile instead.
rem ============================================================

rem ---- Self-elevate if not already running as admin ----
rem fltmc is used instead of "net session": net session queries the Server
rem (LanmanServer) service and fails with error 2 when that service is stopped
rem or disabled, which reports even a full administrator as non-elevated. The
rem script would then relaunch itself with RunAs -- and because RunAs from an
rem already-elevated process shows no UAC prompt, the child would fail the same
rem probe and relaunch again, without bound: an endless chain of console
rem windows, no diagnostic, and nothing configured. fltmc has no service
rem dependency. The result is tested with "neq 0" rather than "if errorlevel 1"
rem because fltmc returns a negative value (0x80070005) when access is denied,
rem which "if errorlevel 1" would read as success.
fltmc >nul 2>&1
if %errorlevel% neq 0 goto :elevate
goto :main

:elevate
rem One-shot guard. The relaunch below passes /elevated, so if the privilege
rem probe still fails in the elevated child we say so instead of relaunching
rem again.
if /i "%~1"=="/elevated" (
    echo.
    echo Administrator rights could not be confirmed even after elevation.
    echo Right-click this file and choose Run as administrator.
    echo.
    pause
    exit /b 1
)
echo Requesting administrator privileges...
rem The path is handed over in an environment variable rather than pasted into
rem the PowerShell text: a path such as C:\Users\O'Brien\Configure-Windows11.bat
rem would otherwise close the quoted string early and leave the -Command text
rem unparseable, so PowerShell would exit before Start-Process ever ran.
set "SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:SELF -ArgumentList '/elevated' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
rem -ErrorAction Stop makes a dismissed UAC prompt reach the catch; without a
rem check here the original script exited silently and the user was left with
rem no idea why nothing had been configured.
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
echo ==== Detecting form factor (desktop vs laptop) ====
set "FF=desktop"
for /f "delims=" %%i in ('powershell -NoProfile -Command "$lap=8,9,10,11,12,14,18,21,30,31,32; $c=@((Get-CimInstance Win32_SystemEnclosure).ChassisTypes); $r='desktop'; foreach($x in $c){ if($lap -contains $x){$r='laptop'} }; if(Get-CimInstance Win32_Battery){$r='laptop'}; $r"') do set "FF=%%i"
echo Detected: %FF%

echo.
echo ==== Taskbar settings ====
rem Align taskbar to left (0 = left, 1 = center)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f
rem Disable Widgets (0 = off)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f
rem Enable "End task" in taskbar right-click (System > For developers)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v TaskbarEndTask /t REG_DWORD /d 1 /f

echo.
echo ==== System tray clock ====
rem Show time and date in the System tray
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSystrayDateTimeValueName /t REG_DWORD /d 1 /f
rem Show seconds: ON for desktop, OFF for laptop (uses more power)
if /i "%FF%"=="laptop" (
    echo  - Laptop detected: disabling seconds in clock
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSecondsInSystemClock /t REG_DWORD /d 0 /f
) else (
    echo  - Desktop detected: enabling seconds in clock
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSecondsInSystemClock /t REG_DWORD /d 1 /f
)
rem Show time in Notification Center
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowClockInNotificationCenter /t REG_DWORD /d 1 /f

echo.
echo ==== Additional Clock 1 (UTC+2 Israel Standard Time) ====
rem Requires "Show time and date in the System tray" (set above)
reg add "HKCU\Control Panel\TimeDate\AdditionalClocks\1" /v Enable /t REG_DWORD /d 1 /f
reg add "HKCU\Control Panel\TimeDate\AdditionalClocks\1" /v DisplayName /t REG_SZ /d "Israel" /f
reg add "HKCU\Control Panel\TimeDate\AdditionalClocks\1" /v TzRegKeyName /t REG_SZ /d "Israel Standard Time" /f

echo.
echo ==== Set time zone automatically ====
rem tzautoupdate Start: 3 = enabled, 4 = disabled
reg add "HKLM\SYSTEM\CurrentControlSet\Services\tzautoupdate" /v Start /t REG_DWORD /d 3 /f
rem Auto time zone needs Location services ON to actually work:
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" /v Status /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v Value /t REG_SZ /d "Allow" /f

echo.
echo ==== Set time automatically + NTP server time.nist.gov ====
rem Enable automatic time sync (Type = NTP; NoSync would disable)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" /v Type /t REG_SZ /d "NTP" /f
rem Make sure the Windows Time service is set to start and running
sc config W32Time start= auto >nul
net start W32Time >nul 2>&1
rem Point at time.nist.gov (0x9 = SpecialInterval + Client) and apply
w32tm /config /manualpeerlist:"time.nist.gov,0x9" /syncfromflags:manual /reliable:no /update
w32tm /config /update
rem Restart service so the new config takes effect, then sync now
net stop W32Time >nul 2>&1
net start W32Time >nul 2>&1
w32tm /resync /force

echo.
echo ==== Clipboard history ====
reg add "HKCU\Software\Microsoft\Clipboard" /v EnableClipboardHistory /t REG_DWORD /d 1 /f

echo.
echo ==== Add Hebrew language + all optional features (Language pack,
echo      Text-to-speech, Handwriting + required Basic typing/fonts) ====
echo (Downloads language pack + Feature-on-Demand packages; may take a while.)
echo (Display / Windows UI language is NOT changed - no -CopyToSettings used.)
rem Install-Language (no -CopyToSettings) = installs the pack + all available
rem FoD features for he-IL WITHOUT setting it as the display language.
rem Falls back to DISM capabilities if the LanguagePackManagement module
rem isn't present (older builds). Then add to the preferred-language list so
rem it shows up with its keyboard, like the GUI "Add a language" flow.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Install-Language he-IL -ErrorAction Stop } catch { Write-Host 'Install-Language unavailable; falling back to DISM capabilities'; $caps = Get-WindowsCapability -Online; foreach($c in $caps){ if($c.State -ne 'Installed' -and ($c.Name -like 'Language.*~he-IL~*' -or $c.Name -like '*und-HEBR*')){ Write-Host (' - ' + $c.Name); Add-WindowsCapability -Online -Name $c.Name -ErrorAction SilentlyContinue } } }; $l = Get-WinUserLanguageList; if (-not ($l.LanguageTag -contains 'he-IL')) { $l.Add('he-IL') }; Set-WinUserLanguageList $l -Force"

echo.
echo ==== Restarting Explorer to apply taskbar/clock changes ====
taskkill /f /im explorer.exe >nul 2>&1
start "" explorer.exe

echo.
echo ============================================================
echo  Done.
echo  - Auto time zone also needs Location ON; this script enabled
echo    the Location service + global consent. If a per-app/Group
echo    Policy blocks location, the auto-tz toggle may still show
echo    off until that is cleared.
echo  - Hebrew optional features depend on Windows Update / internet
echo    access for Feature-on-Demand. Any unavailable feature
echo    (e.g. Hebrew speech recognition) is simply skipped.
echo  - A sign-out/in or reboot is recommended for the language and
echo    notification-center clock to fully settle.
echo ============================================================
echo.
pause
endlocal
