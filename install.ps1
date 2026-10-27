# SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
# SPDX-License-Identifier: Apache-2.0
# Install cig-orchestrator on Windows: orchestrate.cig into
# <prefix>\share\cig-orchestrator and the cigo launcher (.ps1 plus a .cmd shim)
# into <prefix>\bin. Run again to update a checkout; an installed cigo updates
# itself with `cigo update`.
#
#   .\install.ps1
#   .\install.ps1 -Prefix C:\opt\cig
#   .\install.ps1 -Name orch

param(
    [string]$Prefix,
    [string]$Name = 'cigo'
)

$ErrorActionPreference = 'Stop'

if (-not $Prefix) { $Prefix = Join-Path $env:LOCALAPPDATA 'cig-orchestrator' }

$here = Split-Path -Parent $PSCommandPath
$share = Join-Path $Prefix 'share\cig-orchestrator'
$bin = Join-Path $Prefix 'bin'

if (-not (Get-Command cig -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine('install: cig is not on PATH. Install CigScript first:')
    [Console]::Error.WriteLine('  irm https://raw.githubusercontent.com/otmof-ops/CigScript/v1.3.0/install.ps1 | iex')
    exit 1
}

$verOut = ''
try { $verOut = (& cig --version 2>$null | Select-Object -First 1) } catch { }
$verOut = [string]$verOut
$verFields = $verOut -split '\s+'
$version = ''
if ($verFields.Count -ge 2) { $version = $verFields[1] }
if ($version -match '^(\d+)\.(\d+)\.(\d+)') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $tooOld = $false
    if ($major -lt 1) { $tooOld = $true }
    elseif ($major -eq 1 -and $minor -lt 3) { $tooOld = $true }
    if ($tooOld) {
        [Console]::Error.WriteLine("install: cig $version is too old; cig-orchestrator needs 1.3.0 or newer (cig update)")
        exit 1
    }
} else {
    [Console]::Error.WriteLine("install: could not read the version of cig (``cig --version`` said: $verOut)")
    exit 1
}

New-Item -ItemType Directory -Force -Path $share | Out-Null
New-Item -ItemType Directory -Force -Path $bin | Out-Null

$toolSrc = Join-Path $here 'orchestrate.cig'
$toolDst = Join-Path $share 'orchestrate.cig'
if (-not (Test-Path $toolSrc)) {
    [Console]::Error.WriteLine("install: orchestrate.cig not found beside the installer at $toolSrc")
    exit 1
}
Copy-Item -Force $toolSrc $toolDst

$launcherSrc = Join-Path $here 'bin\cigo.ps1'
$cmdSrc = Join-Path $here 'bin\cigo.cmd'
if (-not (Test-Path $launcherSrc)) {
    [Console]::Error.WriteLine("install: cigo.ps1 not found at $launcherSrc")
    exit 1
}
if (-not (Test-Path $cmdSrc)) {
    [Console]::Error.WriteLine("install: cigo.cmd not found at $cmdSrc")
    exit 1
}
$launcherDst = Join-Path $bin ("$Name.ps1")
$cmdDst = Join-Path $bin ("$Name.cmd")

# Rewrite the one $tool line at the top of cigo.ps1 to the installed path.
# A MatchEvaluator delegate stops the regex engine from re-expanding `$` in the
# replacement string, so paths with a literal `$` survive intact.
$content = Get-Content -Raw $launcherSrc
$targetLine = "`$tool = '" + ($toolDst -replace "'", "''") + "'"
$content = [regex]::Replace($content, '(?m)^\$tool = .*$', { param($m) $targetLine })
Set-Content -Path $launcherDst -Value $content -NoNewline

# The .cmd shim uses %~dpn0.ps1 (its own name), so no rewriting; a plain copy.
Copy-Item -Force $cmdSrc $cmdDst

Write-Host "installed $launcherDst (the tool itself: $toolDst)"

# PATH check. Add <prefix>\bin to the USER PATH if it is not already there.
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$parts = @()
if ($userPath) { $parts = $userPath -split ';' | Where-Object { $_ } }
$already = $false
$binFull = $null
try { $binFull = [IO.Path]::GetFullPath($bin) } catch { $binFull = $bin }
foreach ($p in $parts) {
    try {
        if ([IO.Path]::GetFullPath($p) -ieq $binFull) {
            $already = $true
            break
        }
    } catch { }
}
if (-not $already) {
    if ($userPath) { $new = "$userPath;$bin" } else { $new = $bin }
    [Environment]::SetEnvironmentVariable('Path', $new, 'User')
    Write-Host "added $bin to the user PATH; open a new terminal for the change to take effect"
}
