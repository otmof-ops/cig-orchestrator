# SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
# SPDX-License-Identifier: FSL-1.1-ALv2
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

$cigCmd = Get-Command cig -ErrorAction SilentlyContinue
if (-not $cigCmd) {
    [Console]::Error.WriteLine('cigo: cig is not on PATH; install CigScript first: https://github.com/otmof-ops/cig-script')
    exit 127
}

# The cig the launcher would reach, with the launcher's path and its bytes.
$cigReal = ''
try { $cigReal = (Get-Item -LiteralPath $cigCmd.Source).FullName } catch { $cigReal = [string]$cigCmd.Source }
$cigSize = -1
$cigMtime = ''
try {
    $cigItem = Get-Item -LiteralPath $cigReal -ErrorAction Stop
    $cigSize = [int64]$cigItem.Length
    $cigMtime = [string]$cigItem.LastWriteTimeUtc.Ticks
} catch { }

# The launcher floor cache (#117 W3): $env:CIGO_HOME\cig-floor, one line
# `<abs cig path>|<size>|<mtime>|<version>`. A hit (path, size, mtime
# match) reuses the kept version and runs no subprocess; a miss asks `cig
# --version` and writes the cache atomically. An unwritable CIGO_HOME is
# the no-cache case. A failure is never cached, so a `needs_*` bump still
# refuses an old cig. `CIGO_FLOOR_CACHE=off` disables it.
$floorCacheOn = $true
switch -regex ($env:CIGO_FLOOR_CACHE) {
    '^(off|0|no|false)$' { $floorCacheOn = $false }
}
$cigoHomeDir = $env:CIGO_HOME
if (-not $cigoHomeDir) { $cigoHomeDir = Join-Path $HOME '.cig-orchestrator' }
$floorCache = Join-Path $cigoHomeDir 'cig-floor'
$version = ''
$floorHit = $false
if ($floorCacheOn -and $cigSize -ge 0 -and $cigMtime -ne '' -and (Test-Path -LiteralPath $floorCache)) {
    try {
        $cachedLine = (Get-Content -LiteralPath $floorCache -TotalCount 1 -ErrorAction Stop).Trim()
        $expectPrefix = "$cigReal|$cigSize|$cigMtime|"
        if ($cachedLine.StartsWith($expectPrefix)) {
            $cachedVersion = $cachedLine.Substring($expectPrefix.Length)
            if ($cachedVersion -match '^\d+\.\d+\.\d+') {
                $version = $cachedVersion
                $floorHit = $true
            }
        }
    } catch { }
}
$verOut = ''
if (-not $floorHit) {
    try { $verOut = (& cig --version 2>$null | Select-Object -First 1) } catch { }
    $verOut = [string]$verOut
    $verFields = $verOut -split '\s+'
    if ($verFields.Count -ge 2) { $version = $verFields[1] }
}

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
    if ($floorCacheOn -and -not $floorHit -and $cigSize -ge 0 -and $cigMtime -ne '') {
        try {
            New-Item -ItemType Directory -Force -Path $cigoHomeDir | Out-Null
            $floorTmp = "$floorCache.$PID.tmp"
            Set-Content -LiteralPath $floorTmp -Value "$cigReal|$cigSize|$cigMtime|$version" -Encoding utf8 -ErrorAction Stop
            Move-Item -LiteralPath $floorTmp -Destination $floorCache -Force -ErrorAction Stop
        } catch {
            try { Remove-Item -LiteralPath $floorTmp -ErrorAction SilentlyContinue } catch { }
        }
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

$leaveDir = @('adopt', 'help', 'version', 'toolchains', 'update', 'uninstall', 'doctor', 'crash', 'config', 'blacklist', 'quarantine', 'guard', 'undo', 'run-url', 'agent', 'approve', '__dump-rules', '--help', '-h', '--version')
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
    # The installer asks for `__doctor` from wherever it was run, a home
    # folder included: with no project above, it runs from cigo's own empty
    # folder like the commands above.
    $nowDir = (Get-Location).Path
    if ($cmd -eq '__doctor' -and -not ($dir -and (Test-Path -LiteralPath (Join-Path $dir 'cig-tasks.json'))) -and (($nowDir -eq $HOME) -or ($nowDir -eq [IO.Path]::GetPathRoot($nowDir)))) {
        $cigoHome = $env:CIGO_HOME
        if (-not $cigoHome) { $cigoHome = Join-Path $HOME '.cig-orchestrator' }
        $neutral = Join-Path $cigoHome 'here'
        New-Item -ItemType Directory -Force -Path $neutral | Out-Null
        $env:CIGO_CALLER_DIR = $nowDir
        Set-Location -LiteralPath $neutral
    }
}

# `cigo version --json` names the tool and the launcher that ran; `cigo
# __doctor` checks that they agree.
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
