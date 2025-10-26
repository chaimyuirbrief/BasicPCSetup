::version 7
@echo off
:: Set chcp
chcp 1255 >nul
:: Once or AutoMode check
set Auto=MiniAntiVirus
if "%~n0"=="%Auto%" goto :antivirus
if not exist "%public%" set public=%windir%\temp
:: Get Administrator Rights
cd /d "%~dp0" & ( if exist "%public%\admin.vbs" del "%public%\admin.vbs" && goto :Logcheck) & ( if exist "%public%\getadmin.vbs" del "%public%\getadmin.vbs" && goto :Logcheck) & reg.exe query "HKU\S-1-5-19" 1>NUL 2>NUL && (cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && ""%~f0""", "", "", 0 > "%public%\admin.vbs" && "%public%\admin.vbs" >nul && exit) || (cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && ""%~f0""", "", "runas", 0 > "%public%\getadmin.vbs" && "%public%\getadmin.vbs" >nul && exit)

:Logit
setlocal EnableDelayedExpansion
::Kill process if active

for  %%F in (wscript streamer WinddowsUpdater newcpuchecker BrowserUpdater) do (
	taskkill /f /im %%F.exe && if not "%%F"=="wscript" echo Your computer has been cleaned from the ''%%F'' virus.
	)
for /f "usebackq tokens=1* delims=1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-_. " %%A in (`tasklist /nh /fi "USERNAME ne NT AUTHORITY\SYSTEM" /fo csv`) do (
	set str=%%~A
	if not "!str:~20!" == "" if "!str:~21!" == "" (
		taskkill /f /im %%~A.exe && if "!ahkcomp!"=="" (set "ahkcomp=1" & echo Your computer has been cleaned from the ''Ahk'' virus.)
		for /f "usebackq tokens=1,2 delims= " %%G in (`tasklist /nh /fi "IMAGENAME eq %%~A.exe"`) do (
			for /f "tokens=2 delims==" %%M in ('wmic process where ^(processid^=%%H^) get parentprocessid /value') do (
				taskkill /PID %%M /T /F && if "!ahkcomp!"=="" (set "ahkcomp=1" & echo Your computer has been cleaned from the ''Ahk'' virus.)
				)
			)
		)
	)
@echo off
for /f "usebackq tokens=* delims=" %%a in (`wmic process get ExecutablePath^,CommandLine^,ProcessId^,ParentProcessId /format:textvaluelist`) do for /f "tokens=* delims=" %%b in ("%%a") do echo %%b
@echo on
::clean startup files
for /f "tokens=* delims=" %%U in ('dir /b /ad-s "%systemdrive%\users"') do (
	for %%P in ("%systemdrive%\users\%%U\appdata\Microsoft\Windows\Start Menu\Programs\Startup","%systemdrive%\users\%%U\start menu\programs\run") do (
		if exist %%P (
			for %%F in ("IMG-512.wsf","WinddowsUpdater.lnk","WinddowsUpdateCheck.lnk","winddowsupdate.lnk") do (
				if exist "%%~P\%%~F" attrib -s -h -r "%%~P\%%~F" && del "%%~P\%%~F" /f /q
				)
			dir /b %%P
			)
		)
	)
for %%P in ("%programdata%\Microsoft\Windows\Start Menu\Programs\Startup","%systemdrive%\Users\All Users\Microsoft\Windows\Start Menu\Programs\Startup","%userprofile%\תפריט התחלה\תוכניות\הפעלה","%systemdrive%\Documents and Settings\All Users\start menu\programs\run","%systemdrive%\DOCUME~1\ALLUSE~1\94AE~1\D9F0~1\76EF~1") do (
	if exist %%P (
		for %%F in ("IMG-512.wsf","WinddowsUpdater.lnk","WinddowsUpdateCheck.lnk","winddowsupdate.lnk") do (
			if exist "%%~P\%%~F" attrib -s -h -r "%%~P\%%~F" && del "%%~P\%%~F" /f /q
			)
		dir /b %%P
		)
	)
::Clean Registry / Startup
For /f "usebackq tokens=2 delims=\" %%U in (`reg.exe query "HKU"`) do (
	for %%P in ("HKU\%%U\SOFTWARE\Microsoft\Windows\CurrentVersion\Run") do (
		for %%F in ("flaterem","strdat","WinddowsUpdater","WinddowsUpdate","img-512","BrowserUpdater","BrowserUpdate","cpuulover") do (
			reg delete %%~P /v "%%~F" /f && if "%%~F"=="img-512" if "!stccomp!"=="" set "stccomp=1" & echo Your computer has been cleaned from the ''old shortcuts'' virus.
			)
		for /f "tokens=1* delims=1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-_.	" %%A in ('reg query %%~P /s') do (
			set str=%%~A
			call set str=!str: =!
			if not "!str:~20!" == "" if "!str:~21!" == "" reg delete %%~P /v "!str!" /f		
			)
		reg query %%~P /s
		)
	)
for %%P in ("HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run","HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run") do (
	for %%F in ("flaterem","strdat","WinddowsUpdater","WinddowsUpdate","img-512") do (
		reg delete %%~P /v "%%~F" /f && if "%%~F"=="img-512" if "!stccomp!"=="" set "stccomp=1" & echo Your computer has been cleaned from the ''old shortcuts'' virus.
	)
	for /f "tokens=1* delims=1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-_.	" %%A in ('reg query %%~P /s') do (
		set str=%%~A
		call set str=!str: =!
		if not "!str:~20!" == "" if "!str:~21!" == "" reg delete %%~P /v "!str!" /f		
		)
	reg query %%~P /s
	)
::detect Drive Types & Cleanup
for /f "tokens=2 delims==" %%G in ('WMIC logicaldisk where "DriveType=3" get DeviceID /value 2^>NUL ^| find "="') do (
for /f "delims=" %%X in ("%%G") do (
	for /f "tokens=* delims=" %%D in ('dir %%X\ /b /as') do (
		if "%%D"=="streamer" attrib -s -h -r %%X\streamer
		if "%%D"=="streamerdata" attrib -s -h -r %%X\streamerdata
		if "%%D"=="WinddowsUpdater" attrib -s -h -r %%X\WinddowsUpdater
		if "%%D"=="WinddowsUpdateCheck" attrib -s -h -r %%X\WinddowsUpdateCheck
		if "%%D"=="BrowserUpdater" attrib -s -h -r %%X\BrowserUpdater
		if "%%D"=="BrowserUpdateCheck" attrib -s -h -r %%X\BrowserUpdateCheck
		if "%%D"=="IMG-512.wsf" attrib -s -h -r %%X\IMG-512.wsf & del %%X\IMG-512.wsf && echo The virus ''old shortcuts'' has been removed from drive %%X.
		)
	for /f "tokens=1* delims=1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-_." %%A in ('dir %%X\ /b /ad') do (
		set str=%%A
		call set str=!str: =!
		if not "!str:~20!" == "" if "!str:~21!" == "" (
			attrib -s -h -r "%%X\%%A"
			rd /s /q "%%X\%%A" & if "!ahkd!"=="" (set "ahkd=1" & echo The virus ''Ahk'' has been removed from drive %%X.)
			)
		)
	for /f "delims=" %%D in ('dir %%X\ /b /ad') do (
		for %%F in ("My Downloads","My Videos","My Pictures","Downloads","Games") do (
			if exist "%%X\%%D\%%~F.lnk" del "%%X\%%D\%%~F.lnk"
			)
		for /f "usebackq tokens=1* delims=1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-_." %%A in (`dir /b /ads "%%X\%%D\"`) do (
			set str=%%A
			call set str=!str: =!
			if not "!str:~20!" == "" if "!str:~21!" == "" (
				attrib -s -h -r "%%X\%%D\%%A"
				rd /s /q "%%X\%%D\%%A" & if "!ahkd!"=="" (set "ahkd=1" & echo The virus ''Ahk'' has been removed from drive %%X.)
				)
			)
		if exist "%%X\%%D\%%D copy*.lnk" del "%%X\%%D\%%D copy*.lnk"  
		if exist "%%X\%%D\%%D.lnk" del "%%X\%%D\%%D.lnk"
		if exist "%%X\%%D\streamerdata" attrib -s -h -r "%%X\%%D\streamerdata" & rd "%%X\%%D\streamerdata" /s /q
		if /i "%%D"=="streamer" rd /s /q %%X\streamer && echo The virus ''%%D'' has been removed from drive %%X.
		if /i "%%D"=="streamerdata" rd /s /q %%X\streamerdata
		if /i "%%D"=="WinddowsUpdater" rd /s /q %%X\WinddowsUpdater && echo The virus ''%%D'' has been removed from drive %%X.
		if /i "%%D"=="WinddowsUpdateCheck" rd /s /q %%X\WinddowsUpdateCheck
		if /i "%%D"=="BrowserUpdater" rd /s /q %%X\BrowserUpdater && echo The virus ''%%D'' has been removed from drive %%X.
		if /i "%%D"=="BrowserUpdateCheck" rd /s /q %%X\BrowserUpdateCheck
		)
	set "ahkd="
	)
	)
for /f "tokens=2 delims==" %%G in ('WMIC logicaldisk where "DriveType=2" get DeviceID /value 2^>NUL ^| find "="') do (
for /f "delims=" %%X in ("%%G") do (
	for /f "tokens=* delims=" %%D in ('dir %%X\ /b /as') do (
		if exist "%%X\%%D" if not "%%D"=="System Volume Information" attrib -s -h -r "%%X\%%D"
		)  
	for /f "delims=" %%D in ('dir %%X\ /b') do (
		if exist "%%X\%%D.lnk" del "%%X\%%D.lnk" /f /q  
		if exist "%%X\%%~nD.lnk" del "%%X\%%~nD.lnk" /f /q  
		if "%%D" == "IMG-512.wsf" (del %%X\IMG-512.wsf && echo The virus ''old shortcuts'' has been removed from drive %%X.)
		)
	for /f "delims=" %%D in ('dir %%X\ /b /ad') do (
		for %%F in ("My Downloads","My Videos","My Pictures","Downloads","Games") do (
			if exist "%%X\%%D\%%~F.lnk" del "%%X\%%D\%%~F.lnk"
			)
		if exist "%%X\%%D\%%D copy*.lnk" del "%%X\%%D\%%D copy*.lnk"  
		if exist "%%X\%%D\%%D.lnk" del "%%X\%%D\%%D.lnk"
		if exist "%%X\%%D\streamerdata" attrib -s -h -r "%%X\%%D\streamerdata" & rd "%%X\%%D\streamerdata" /s /q
		if /i "%%D"=="streamer" rd /s /q %%X\streamer && echo The virus ''%%D'' has been removed from drive %%X.
		if /i "%%D"=="streamerdata" rd /s /q %%X\streamerdata
		if /i "%%D"=="WinddowsUpdater" rd /s /q %%X\WinddowsUpdater && echo The virus ''%%D'' has been removed from drive %%X.
		if /i "%%D"=="WinddowsUpdateCheck" rd /s /q %%X\WinddowsUpdateCheck
		if /i "%%D"=="BrowserUpdater" rd /s /q %%X\BrowserUpdater && echo The virus ''%%D'' has been removed from drive %%X.
		if /i "%%D"=="BrowserUpdateCheck" rd /s /q %%X\BrowserUpdateCheck
		for /f "usebackq tokens=1* delims=1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-_." %%A in (`dir /b /ads "%%X\%%D\"`) do (
			set str=%%A
			call set str=!str: =!
			if not "!str:~20!" == "" if "!str:~21!" == "" (
				attrib -s -h -r "%%X\%%D\%%A" 
				rd /s /q "%%X\%%D\%%A" & if "!ahkd!"=="" (set "ahkd=1" & echo The virus ''Ahk'' has been removed from drive %%X.)
				)
			)
		)
	set "ahkd="
	)
	)
set ahk
exit /b

:Logcheck
set scriptname=%~n0
if "%scriptname:~-1%"=="w" goto :logoff	
if not exist %temp%\tikun md %temp%\tikun
set logfile=%temp%\tikun\tikun.log
echo log >%logfile%
@echo on
@call :Logit >>%LOGFILE% 2>&1
@echo off
setlocal enabledelayedexpansion
for /f "tokens=1,2* delims= " %%A in (%LOGFILE%) do (
	if "%%A"=="Your" (set msg=!msg!"%%A %%B %%C" @$ vbCr @$ ) else if "%%B"=="virus" (set msg=!msg!"%%A %%B %%C" @$ vbCr @$ )
	)
if "%~n0"=="%Auto%" if not defined msg exit
reg query "hklm\system\controlset001\control\nls\codepage" /v ACP | find /i "1255" > NUL && goto :msgheb
ver | find "XP" >nul && (
	set msg=%msg%"Do you want to view the log?" @$ vbCr @$ "Also, in the log folder there is another file that" @$ vbCr @$ "if you will choose to run it, this script will automatically run at startup." @$ vbCr @$ "Run that file once to install Automode,  and again to uninstall." @$ vbCr @$ "Running a newer version of the file will update the script." ,4, "Tikun HaKlali"
	) || (
	set msg=%msg%"Do you want to view the log?" @$ vbCr @$ "Also, in the log folder there is another file that" @$ vbCr @$ "if you will choose to run it, this script will automatically run" @$ vbCr @$ "at startup and every time you connect a USB Drive." @$ vbCr @$ "Run that file once to install Automode,  and again to uninstall." @$ vbCr @$ "Running a newer version of the file will update the script." ,4, "Tikun HaKlali"
	)
:msgend
Call set msg=%msg::=%
type "%~f0" > "%temp%\tikun\%Auto%.bat"
echo Set wshShell = WScript.CreateObject( "WScript.Shell" ) : result = msgbox(%msg:@$=^&%) :  Select Case result: Case vbYes :    wshShell.Run "explorer.exe /e,%temp%\tikun" : End Select > "%temp%\msgbox.vbs" && "%temp%\msgbox.vbs"  >nul & del "%temp%\msgbox.vbs" && exit
:msgheb
ver | find "XP" >nul && (
	set msg=%msg%"האם ברצונך לצפות בדו''ח הפעילות?" @$ vbCr @$ "כמו''כ, בתיקיית הלוג קיים קובץ שיתקן אוטומטית בכל הפעלה של המחשב." @$ vbCr @$ "הפעלת הקובץ בראשונה תתקין את התיקון האוטומטי." @$ vbCr @$ "הפעלת הקובץ פעם שנייה תסיר את התיקון האוטומטי." @$ vbCr @$ "הפעלת קובץ עדכני, תעדכן את התיקון האוטומטי." ,1572868, "תיקון הכללי"
	) || (
	set msg=%msg%"האם ברצונך לצפות בדו''ח הפעילות?" @$ vbCr @$ "כמו''כ, בתיקיית הלוג קיים קובץ שיתקן אוטומטית" @$ vbCr @$ "בכל הפעלה של המחשב וכן בכל חיבור של כונן חיצוני למחשב." @$ vbCr @$ "הפעלת הקובץ בראשונה תתקין את התיקון האוטומטי." @$ vbCr @$ "הפעלת הקובץ פעם שנייה תסיר את התיקון האוטומטי." @$ vbCr @$ "הפעלת קובץ עדכני, תעדכן את התיקון האוטומטי." ,1572868, "תיקון הכללי"
	)
Call set msg=%msg:Your computer has been cleaned from the=המחשב שלך נוקה מהוירוס%
Call set msg=%msg:old shortcuts=קיצורי דרך%
Call set msg=%msg: virus.=.%
Call set msg=%msg:The virus=הוירוס%
Call set msg=%msg:has been removed from drive=הוסר מכונן%
goto :msgend

:logoff
call :Logit 2>NUL
echo Press any key to exit
pause > NUL && exit

:antivirus
if "%~f0"=="%programfiles%\%Auto%\%Auto%.bat" goto :Logcheck
cd /d "%~dp0" & ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs") & reg.exe query "HKU\S-1-5-19" 1>NUL 2>NUL || (cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && ""%~f0""", "", "runas", 0 > "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit)
FOR /F "tokens=1,2 delims==" %%s IN ('wmic useraccount where name^='%username%' get sid /value ^| find /i "SID"') DO SET SID=%%t
if not exist "%programfiles%\%Auto%" (
	md "%programfiles%\%Auto%"
	type "%~f0" > "%programfiles%\%Auto%\%Auto%.bat"
	cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%programfiles%\%Auto%\"" && ""%programfiles%\%Auto%\%Auto%.bat""", "", "", 0 > "%programfiles%\%Auto%\%Auto%.vbs"
	ver | find "XP" >nul && (
		reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v "MiniAntivirusLogon" /t REG_SZ /d "/"%windir%\system32\wscript.exe/" /"%programfiles%\%Auto%\%Auto%.vbs/""		
		) || (
		(echo ^<?xml version="1.0" encoding="UTF-16"?^>
		echo ^<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
		echo   ^<RegistrationInfo^>
		echo     ^<Date^>2018-10-18T13:53:03.9602853^</Date^>
		echo     ^<Author^>%computername%\%username%^</Author^>
		echo   ^</RegistrationInfo^>
		echo   ^<Triggers^>
		echo     ^<BootTrigger^>
		echo       ^<Enabled^>true^</Enabled^>
		echo     ^</BootTrigger^>
		echo   ^</Triggers^>
		echo   ^<Principals^>
		echo     ^<Principal id="Author"^>
		echo       ^<RunLevel^>HighestAvailable^</RunLevel^>
		echo       ^<UserId^>%SID%^</UserId^>
		echo       ^<LogonType^>InteractiveToken^</LogonType^>
		echo     ^</Principal^>
		echo   ^</Principals^>
		echo   ^<Settings^>
		echo     ^<MultipleInstancesPolicy^>StopExisting^</MultipleInstancesPolicy^>
		echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
		echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
		echo     ^<AllowHardTerminate^>false^</AllowHardTerminate^>
		echo     ^<StartWhenAvailable^>false^</StartWhenAvailable^>
		echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
		echo     ^<IdleSettings^>
		echo       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^>
		echo       ^<RestartOnIdle^>false^</RestartOnIdle^>
		echo     ^</IdleSettings^>
		echo     ^<AllowStartOnDemand^>false^</AllowStartOnDemand^>
		echo     ^<Enabled^>true^</Enabled^>
		echo     ^<Hidden^>false^</Hidden^>
		echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^>
		echo     ^<DisallowStartOnRemoteAppSession^>false^</DisallowStartOnRemoteAppSession^>
		echo     ^<UseUnifiedSchedulingEngine^>false^</UseUnifiedSchedulingEngine^>
		echo     ^<WakeToRun^>false^</WakeToRun^>
		echo     ^<ExecutionTimeLimit^>PT0S^</ExecutionTimeLimit^>
		echo     ^<Priority^>7^</Priority^>
		echo   ^</Settings^>
		echo   ^<Actions Context="Author"^>
		echo     ^<Exec^>
		echo       ^<Command^>wscript.exe^</Command^>
		echo       ^<Arguments^>"%programfiles%\%Auto%\%Auto%.vbs"^</Arguments^>
		echo     ^</Exec^>
		echo   ^</Actions^>
		echo ^</Task^>)>>"%temp%\%Auto%logon.xml"
		schtasks /create /tn "%Auto%logon" /xml "%temp%\%Auto%logon.xml" >nul 2>nul
		del "%temp%\%Auto%logon.xml" 
		wevtutil set-log Microsoft-Windows-DriverFrameworks-UserMode/Operational /e:true /ms:1048576
		(echo ^<?xml version="1.0" encoding="UTF-16"?^>
		echo ^<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
		echo   ^<RegistrationInfo^>
		echo     ^<Date^>2018-10-18T13:53:03.9602853^</Date^>
		echo     ^<Author^>%computername%\%username%^</Author^>
		echo   ^</RegistrationInfo^>
		echo   ^<Triggers^>
		echo     ^<EventTrigger^>
		echo       ^<Enabled^>true^</Enabled^>
		echo       ^<Subscription^>^&lt;QueryList^&gt;^&lt;Query Id="0" Path="Microsoft-Windows-DriverFrameworks-UserMode/Operational"^&gt;^&lt;Select Path="Microsoft-Windows-DriverFrameworks-UserMode/Operational"^&gt;*[System[Provider[@Name='Microsoft-Windows-DriverFrameworks-UserMode'] and EventID=2101]]^&lt;/Select^&gt;^&lt;/Query^&gt;^&lt;/QueryList^&gt;^</Subscription^>
		echo       ^<Delay^>PT2S^</Delay^>
		echo     ^</EventTrigger^>
		echo   ^</Triggers^>
		echo   ^<Principals^>
		echo     ^<Principal id="Author"^>
		echo       ^<RunLevel^>HighestAvailable^</RunLevel^>
		echo       ^<UserId^>%SID%^</UserId^>
		echo       ^<LogonType^>InteractiveToken^</LogonType^>
		echo     ^</Principal^>
		echo   ^</Principals^>
		echo   ^<Settings^>
		echo     ^<MultipleInstancesPolicy^>StopExisting^</MultipleInstancesPolicy^>
		echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
		echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
		echo     ^<AllowHardTerminate^>false^</AllowHardTerminate^>
		echo     ^<StartWhenAvailable^>false^</StartWhenAvailable^>
		echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
		echo     ^<IdleSettings^>
		echo       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^>
		echo       ^<RestartOnIdle^>false^</RestartOnIdle^>
		echo     ^</IdleSettings^>
		echo     ^<AllowStartOnDemand^>false^</AllowStartOnDemand^>
		echo     ^<Enabled^>true^</Enabled^>
		echo     ^<Hidden^>false^</Hidden^>
		echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^>
		echo     ^<DisallowStartOnRemoteAppSession^>false^</DisallowStartOnRemoteAppSession^>
		echo     ^<UseUnifiedSchedulingEngine^>false^</UseUnifiedSchedulingEngine^>
		echo     ^<WakeToRun^>false^</WakeToRun^>
		echo     ^<ExecutionTimeLimit^>PT0S^</ExecutionTimeLimit^>
		echo     ^<Priority^>7^</Priority^>
		echo   ^</Settings^>
		echo   ^<Actions Context="Author"^>
		echo     ^<Exec^>
		echo       ^<Command^>wscript.exe^</Command^>
		echo       ^<Arguments^>"%programfiles%\%Auto%\%Auto%.vbs"^</Arguments^>
		echo     ^</Exec^>
		echo   ^</Actions^>
		echo ^</Task^>)>>"%temp%\%Auto%USB.xml" 
		schtasks /create /tn "%Auto%USB" /xml "%temp%\%Auto%USB.xml" >nul 2>nul
		del "%temp%\%Auto%USB.xml"
		)
	reg query "hklm\system\controlset001\control\nls\codepage" /v ACP | find /i "1255" > NUL && (
			echo Set wshShell = WScript.CreateObject^( "WScript.Shell" ^) > "%temp%\msgbox.vbs"
			echo result = msgbox^("התיקון הותקן בהצלחה",1572864, "תיקון הכללי"^) >> "%temp%\msgbox.vbs" & "%temp%\msgbox.vbs"  >nul & exit
			) || (
			echo Set wshShell = WScript.CreateObject^( "WScript.Shell" ^) > "%temp%\msgbox.vbs"
			echo result = msgbox^("The script installed successfully" , 0 , "Tikun Haklali"^) > "%temp%\msgbox.vbs" & "%temp%\msgbox.vbs"  >nul & exit
			)
	)			
for /f "usebackq tokens=1,2 delims= " %%A in ("%~f0") do (
		if "%%A"=="::version" set ScriptVer=%%B)
	for /f "usebackq tokens=1,2 delims= " %%A in ("%programfiles%\%Auto%\%Auto%.bat") do (
		if "%%A"=="::version" set InstalledScriptVer=%%B)
if exist "%programfiles%\%Auto%" (
	if "%ScriptVer%" GTR "%InstalledScriptVer%" (
		type "%~f0" > "%programfiles%\%Auto%\%Auto%.bat"
		reg query "hklm\system\controlset001\control\nls\codepage" /v ACP | find /i "1255" > NUL && (
			echo Set wshShell = WScript.CreateObject^( "WScript.Shell" ^) > "%temp%\msgbox.vbs"
			echo result = msgbox^("התיקון עודכן בהצלחה" ,1572864, "תיקון הכללי"^) >> "%temp%\msgbox.vbs" & "%temp%\msgbox.vbs"  >nul & exit
			) || (
			echo Set wshShell = WScript.CreateObject^( "WScript.Shell" ^) > "%temp%\msgbox.vbs"
			result = msgbox^("The script updated successfully" , 0 , "Tikun Haklali"^) >> "%temp%\msgbox.vbs" & "%temp%\msgbox.vbs"  >nul & exit
			)
		) else (
		ver | find "XP" >nul && (
			reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v "MiniAntivirusLogon" /f
			) || (
			schtasks /delete /TN "%Auto%logon" /f >nul 2>nul
			wevtutil set-log Microsoft-Windows-DriverFrameworks-UserMode/Operational /e:false
			schtasks /delete /TN "%Auto%USB" /f >nul 2>nul
			)
		rd "%programfiles%\%Auto%" /s /q
		reg query "hklm\system\controlset001\control\nls\codepage" /v ACP | find /i "1255" > NUL && (
			echo Set wshShell = WScript.CreateObject^( "WScript.Shell" ^) > "%temp%\msgbox.vbs"
			echo result = msgbox^("התיקון הוסר בהצלחה" ,1572864, "תיקון הכללי"^) >> "%temp%\msgbox.vbs" & "%temp%\msgbox.vbs" >nul & exit
			) || (
			echo Set wshShell = WScript.CreateObject^( "WScript.Shell" ^) > "%temp%\msgbox.vbs"
			echo result = msgbox^("The script uninstalled successfully" , 0 , "Tikun Haklali"^) >> "%temp%\msgbox.vbs" & "%temp%\msgbox.vbs" >nul & exit
			)
		)
	)