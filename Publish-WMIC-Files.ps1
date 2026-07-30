<#
.SYNOPSIS
    Publishes the current (Windows-serviced) WMIC / WBEM files from this machine
    into the BasicPCSetup repo so target machines always get up-to-date files.

.DESCRIPTION
    Run this on ONE machine that:
      * still has WMIC in C:\Windows\System32\wbem, and
      * receives Windows Updates (so those files stay current).

    Each run copies the live WMIC files into the repo's "WMIC files" folder and,
    if any of them changed since last time (e.g. after a cumulative update),
    commits and pushes the update. Target machines then pull the latest with
    "Install WMIC Files.bat" — no manual copying, no slow DISM.

    Intended to be run on a schedule via Task Scheduler. See the example below.

.PARAMETER RepoDir
    Path to a local git clone of the BasicPCSetup repo. Defaults to the folder
    this script lives in (works when the script is run from inside the clone).

.PARAMETER NoPush
    Copy and commit but do not push (useful for testing).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File "Publish-WMIC-Files.ps1"

.EXAMPLE
    # Register a daily scheduled task (run once, from an elevated PowerShell):
    $action  = New-ScheduledTaskAction -Execute 'powershell.exe' `
                 -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\BasicPCSetup\Publish-WMIC-Files.ps1"'
    $trigger = New-ScheduledTaskTrigger -Daily -At 3am
    Register-ScheduledTask -TaskName 'Publish WMIC Files' -Action $action -Trigger $trigger `
                 -RunLevel Highest -Description 'Push latest serviced WMIC files to BasicPCSetup'
#>

[CmdletBinding()]
param(
    [string]$RepoDir = $PSScriptRoot,
    [switch]$NoPush
)

$ErrorActionPreference = 'Stop'

# The set of WMIC / WBEM files that make up the tool. Keep this list in sync
# with "Install WMIC Files.bat".
$files = @(
    'WMIC.exe','WMIC.exe.mui','WMICOOKR.dll','WBEMCons.mof','WbemCons.mfl',
    'wbemcntl.dll','wbemcntl.dll.mui','wbemcons.dll','wbemcore.dll','wbemcore.dll.mui',
    'wbemdisp.dll','wbemdisp.tlb','wbemess.dll','wbemprox.dll','wbemsvc.dll',
    'wbemtest.exe','wbemtest.exe.mui','wmiutils.dll','wmiutils.dll.mui'
)

$source = Join-Path $env:SystemRoot 'System32\wbem'
$dest   = Join-Path $RepoDir 'WMIC files'

Write-Host "Source (live WMIC files): $source"
Write-Host "Destination (repo):       $dest"
Write-Host ""

if (-not (Test-Path (Join-Path $RepoDir '.git'))) {
    throw "RepoDir '$RepoDir' is not a git clone. Point -RepoDir at your BasicPCSetup clone."
}
if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

$copied  = 0
$missing = @()
foreach ($f in $files) {
    $src = Join-Path $source $f
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $dest $f) -Force
        $copied++
    } else {
        $missing += $f
    }
}

Write-Host "Copied $copied of $($files.Count) files into the repo."
if ($missing.Count -gt 0) {
    Write-Warning "Not found on this machine (skipped): $($missing -join ', ')"
    Write-Warning "This machine may not have a complete WMIC install; use a machine that still has WMIC."
}

# Commit and push only if something actually changed.
Push-Location $RepoDir
try {
    $status = git status --porcelain -- 'WMIC files'
    if ([string]::IsNullOrWhiteSpace($status)) {
        Write-Host "No changes - WMIC files are already up to date. Nothing to publish." -ForegroundColor Green
        return
    }

    git add -- 'WMIC files' | Out-Null

    $stamp = git log -1 --format=%cd --date=short 2>$null
    $version = (Get-Item (Join-Path $source 'WMIC.exe') -ErrorAction SilentlyContinue).VersionInfo.ProductVersion
    $msg = "Update WMIC files from serviced machine"
    if ($version) { $msg += " (WMIC.exe $version)" }

    git commit -m $msg | Out-Null
    Write-Host "Committed: $msg" -ForegroundColor Green

    if ($NoPush) {
        Write-Host "-NoPush set; skipping push." -ForegroundColor Yellow
    } else {
        # Retry push with exponential backoff on transient network failures.
        $delays = 2,4,8,16
        $pushed = $false
        for ($i = 0; $i -lt ($delays.Count + 1) -and -not $pushed; $i++) {
            git push
            if ($LASTEXITCODE -eq 0) {
                $pushed = $true
            } elseif ($i -lt $delays.Count) {
                Start-Sleep -Seconds $delays[$i]
            }
        }
        if ($pushed) {
            Write-Host "Pushed updated WMIC files to the repo." -ForegroundColor Green
        } else {
            throw "git push failed after retries."
        }
    }
} finally {
    Pop-Location
}
