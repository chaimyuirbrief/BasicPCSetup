<#
    Deploy-OpenSSHServer.ps1
    Installs OpenSSH Server from Microsoft's portable release zip instead of the
    slow Feature-on-Demand pull. Replicates everything the FoD does:
        1. Drops the binaries
        2. Registers the sshd + ssh-agent services (via Install-sshd.ps1)
        3. Adds the inbound firewall rule on port 22
        4. Starts sshd and sets it to Automatic

    Runs correctly in an interactive elevated shell OR under SYSTEM (ScreenConnect
    backstage) - no reliance on the calling user's Downloads folder.

    Safe to re-run: stops an existing sshd, re-installs cleanly, won't duplicate
    the firewall rule.
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# ---- Config -----------------------------------------------------------------
$Url       = 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/download/OpenSSH-Win64.zip'
$WorkDir   = 'C:\Temp'                       # context-independent scratch space
$Zip       = Join-Path $WorkDir 'OpenSSH-Win64.zip'
$InstallTo = 'C:\Program Files\OpenSSH'      # final home for the binaries
# -----------------------------------------------------------------------------

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# 0. Prep scratch dir + force modern TLS (older Win builds default to 1.0)
Write-Step "Preparing $WorkDir"
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. If sshd is already running from a prior install, stop it so we can overwrite
if (Get-Service -Name sshd -ErrorAction SilentlyContinue) {
    Write-Step "Existing sshd found - stopping before reinstall"
    Stop-Service sshd -Force -ErrorAction SilentlyContinue
    # Unregister old services so Install-sshd.ps1 registers fresh
    if (Test-Path "$InstallTo\uninstall-sshd.ps1") {
        & "$InstallTo\uninstall-sshd.ps1"
    }
}

# 2. Download the portable zip
Write-Step "Downloading OpenSSH from Microsoft"
Invoke-WebRequest -Uri $Url -OutFile $Zip -UseBasicParsing
Write-Host "    Saved to $Zip"

# 3. Extract. The zip contains a top-level 'OpenSSH-Win64' folder, so extract to
#    a staging path then move the inner contents up to $InstallTo.
Write-Step "Extracting to $InstallTo"
$stage = Join-Path $WorkDir 'ssh_stage'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
Expand-Archive -Path $Zip -DestinationPath $stage -Force

$inner = Join-Path $stage 'OpenSSH-Win64'
if (-not (Test-Path $inner)) { $inner = $stage }   # fallback if layout changes

New-Item -ItemType Directory -Path $InstallTo -Force | Out-Null
Copy-Item -Path (Join-Path $inner '*') -Destination $InstallTo -Recurse -Force

# 4. Register the services (this is the step a plain file-copy skips)
Write-Step "Registering sshd + ssh-agent services"
& powershell.exe -ExecutionPolicy Bypass -File (Join-Path $InstallTo 'Install-sshd.ps1')

# 5. Firewall rule (portable zip does NOT create it; FoD does)
Write-Step "Ensuring inbound firewall rule on TCP 22"
if (-not (Get-NetFirewallRule -Name 'sshd' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'sshd' -DisplayName 'OpenSSH Server (sshd)' `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    Write-Host "    Rule created"
} else {
    Write-Host "    Rule already present - leaving as-is"
}

# 6. Start + set Automatic (both sshd and the agent)
Write-Step "Starting services"
Set-Service -Name sshd      -StartupType Automatic
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service sshd
Start-Service ssh-agent

# 7. Add install dir to system PATH so ssh/scp work from any prompt
Write-Step "Adding $InstallTo to system PATH (if missing)"
$sysPath = [Environment]::GetEnvironmentVariable('Path','Machine')
if ($sysPath -notlike "*$InstallTo*") {
    [Environment]::SetEnvironmentVariable('Path', "$sysPath;$InstallTo", 'Machine')
    Write-Host "    Added (new shells will pick it up)"
} else {
    Write-Host "    Already on PATH"
}

# 8. Verify
Write-Step "Verification"
$svc = Get-Service sshd
Write-Host ("    sshd service : {0}" -f $svc.Status)
$listen = Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue
if ($listen) {
    Write-Host "    Listening on : port 22  [OK]" -ForegroundColor Green
} else {
    Write-Host "    NOT listening on 22 - check sshd log at C:\ProgramData\ssh\logs" -ForegroundColor Yellow
}

# 9. Cleanup scratch (leave the zip if you want to cache it; comment out to keep)
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue

Write-Step "Done."
Write-Host "Connect with:  ssh <user>@<this-host-ip>" -ForegroundColor Cyan
