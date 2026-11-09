# SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
# SPDX-License-Identifier: Apache-2.0
# cigo: the launcher for cig-orchestrator. All the logic is in orchestrate.cig;
# this finds it, finds the project (the nearest directory up that has a
# cig-tasks.json), checks the cig it is about to hand the tool to, and passes
# cig the flags that are cig's own.
$tool = Join-Path (Split-Path -Parent $PSScriptRoot) 'orchestrate.cig'
# The cig this cigo is written for: the same floor as the `# cig` pin in the
# tool, checked here for cigs too old to read the pin themselves.
$needsMajor = 1
$needsMinor = 20
$needsPatch = 0

if (-not (Get-Command cig -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine('cigo: cig is not on PATH; install CigScript first: https://github.com/otmof-ops/cig-script')
    exit 127
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
    if ($major -lt $needsMajor) { $tooOld = $true }
    elseif ($major -eq $needsMajor -and $minor -lt $needsMinor) { $tooOld = $true }
    elseif ($major -eq $needsMajor -and $minor -eq $needsMinor -and $patch -lt $needsPatch) { $tooOld = $true }
    if ($tooOld) {
        [Console]::Error.WriteLine("cigo: cig $version is too old; cig-orchestrator needs $needsMajor.$needsMinor.$needsPatch or newer (cig update)")
        exit 2
    }
} else {
    [Console]::Error.WriteLine("cigo: could not read the version of cig (``cig --version`` said: $verOut)")
    exit 2
}

# The flag lists are single words, split on purpose.
$global = @()
$run = @()
$argsList = @()
if ($args) { $argsList = @($args) }
$i = 0
while ($i -lt $argsList.Count) {
    $a = [string]$argsList[$i]
    if ($a -eq '--dry-run' -or $a -eq '--no-check' -or $a -eq '--no-rollback') {
        $run += $a
        $i++
    } elseif ($a -eq '--max-steps') {
        if ($i + 1 -lt $argsList.Count) {
            $run += $a
            $run += [string]$argsList[$i + 1]
            $i += 2
        } else {
            [Console]::Error.WriteLine('cigo: --max-steps needs a number (--max-steps N or --max-steps=N)')
            exit 2
        }
    } elseif ($a -like '--max-steps=*') {
        $run += $a
        $i++
    } elseif ($a -eq '--json' -or $a -eq '--no-color' -or $a -eq '--no-doctor' -or $a -eq '--plain') {
        $global += $a
        $i++
    } else {
        break
    }
}
$rest = @()
if ($i -lt $argsList.Count) { $rest = @($argsList[$i..($argsList.Count - 1)]) }

$cmd = 'help'
if ($rest.Count -gt 0) { $cmd = [string]$rest[0] }

$leaveDir = @('adopt', 'help', 'version', 'toolchains', 'update', 'crash', 'config', 'blacklist', 'quarantine', 'guard', 'undo', 'run-url', 'agent', 'approve', '--help', '-h', '--version')
# From the home folder itself (or a drive's root), cig would take all of it
# as the run's pack and watch every file in it around each step: these run
# from an empty folder of cigo's instead, told where you are.
$here = (Get-Location).Path
if (($leaveDir -contains $cmd) -and ($cmd -ne 'adopt') -and (($here -eq $HOME) -or ($here -eq [IO.Path]::GetPathRoot($here)))) {
    $cigoHome = $env:CIGO_HOME
    if (-not $cigoHome) { $cigoHome = Join-Path $HOME '.cig-orchestrator' }
    $neutral = Join-Path $cigoHome 'here'
    New-Item -ItemType Directory -Force -Path $neutral | Out-Null
    $env:CIGO_CALLER_DIR = $here
    Set-Location -LiteralPath $neutral
}
if ($leaveDir -notcontains $cmd) {
    $startDir = (Get-Location).Path
    $dir = $startDir
    while ($dir) {
        if (Test-Path -LiteralPath (Join-Path $dir 'cig-tasks.json')) { break }
        $parent = Split-Path -Parent $dir
        if (-not $parent -or $parent -eq $dir) { $dir = $null; break }
        $dir = $parent
    }
    if ($dir -and (Test-Path -LiteralPath (Join-Path $dir 'cig-tasks.json')) -and ($dir -ne $startDir)) {
        Set-Location -LiteralPath $dir
    }
}

# `cigo update` replaces the tool and the launcher where they are installed;
# `cigo version --json` names them.
$env:CIGO_TOOL = $tool
$env:CIGO_LAUNCHER = $PSCommandPath

$cigArgs = @()
foreach ($g in $global) { $cigArgs += [string]$g }
$cigArgs += 'run'
foreach ($r in $run) { $cigArgs += [string]$r }
$cigArgs += [string]$tool
$cigArgs += '--'
foreach ($a in $rest) { $cigArgs += [string]$a }

& cig @cigArgs
exit $LASTEXITCODE
