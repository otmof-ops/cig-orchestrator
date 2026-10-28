# SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
# SPDX-License-Identifier: Apache-2.0
# Install cig-orchestrator on Windows: orchestrate.cig into
# <prefix>\share\cig-orchestrator, and into <prefix>\bin the cigo.cmd shim
# that `cigo` resolves to, beside the cigo.launch.ps1 it runs. Run again to
# update a checkout; an installed cigo updates itself with `cigo update`.
#
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#   .\install.ps1 -Prefix C:\opt\cig       (where scripts may run)
#   .\install.ps1 -Name orch

param(
    [string]$Prefix,
    [string]$Name = 'cigo'
)

$ErrorActionPreference = 'Stop'

if (-not $Prefix) { $Prefix = Join-Path $env:LOCALAPPDATA 'cig-orchestrator' }
# A relative prefix is read from here and written into the launcher as it
# is, which only works from this directory: make it absolute first.
$Prefix = [IO.Path]::GetFullPath($Prefix)

$here = Split-Path -Parent $PSCommandPath
$share = Join-Path $Prefix 'share\cig-orchestrator'
$bin = Join-Path $Prefix 'bin'

if (-not (Get-Command cig -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine('install: cig is not on PATH. Install CigScript first:')
    [Console]::Error.WriteLine('  irm https://raw.githubusercontent.com/otmof-ops/CigScript/v1.4.2/install.ps1 | iex')
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
    elseif ($major -eq 1 -and $minor -eq 3 -and $patch -lt 1) { $tooOld = $true }
    if ($tooOld) {
        [Console]::Error.WriteLine("install: cig $version is too old; cig-orchestrator needs 1.4.2 or newer (cig update)")
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
if (-not (Test-Path -LiteralPath $toolSrc)) {
    [Console]::Error.WriteLine("install: orchestrate.cig not found beside the installer at $toolSrc")
    exit 1
}
Copy-Item -LiteralPath $toolSrc -Destination $toolDst -Force

$launcherSrc = Join-Path $here 'bin\cigo.launch.ps1'
$cmdSrc = Join-Path $here 'bin\cigo.cmd'
if (-not (Test-Path -LiteralPath $launcherSrc)) {
    [Console]::Error.WriteLine("install: cigo.launch.ps1 not found at $launcherSrc")
    exit 1
}
if (-not (Test-Path -LiteralPath $cmdSrc)) {
    [Console]::Error.WriteLine("install: cigo.cmd not found at $cmdSrc")
    exit 1
}
$launcherDst = Join-Path $bin ("$Name.launch.ps1")
$cmdDst = Join-Path $bin ("$Name.cmd")

# Rewrite the one $tool line at the top of the launcher to the installed path.
# The path travels as base64 of its UTF-8 bytes: no apostrophe (the curly
# ones included), `$`, backtick or non-ASCII letter can break the line,
# whichever PowerShell edition wrote it or reads it. A MatchEvaluator
# delegate keeps the regex engine from expanding `$` in the replacement.
$content = Get-Content -Raw -LiteralPath $launcherSrc
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($toolDst))
$targetLine = "`$tool = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$b64'))"
$content = [regex]::Replace($content, '(?m)^\$tool = [^\r\n]*', { param($m) $targetLine })
[IO.File]::WriteAllText($launcherDst, $content, (New-Object Text.UTF8Encoding $false))

# The .cmd shim uses %~dpn0.launch.ps1 (its own name), so no rewriting; a
# plain copy.
Copy-Item -LiteralPath $cmdSrc -Destination $cmdDst -Force

# 0.4.0 installed the launcher as <name>.ps1, which PowerShell ran before
# the shim; one left beside the shim would still win.
$stale = Join-Path $bin ("$Name.ps1")
if (Test-Path -LiteralPath $stale) { Remove-Item -LiteralPath $stale -Force }

Write-Host "installed $cmdDst and $launcherDst (the tool itself: $toolDst)"

# PATH: <prefix>\bin goes on the user PATH as the registry holds it, so
# entries written as %VAR% stay unexpanded (reading them through .NET
# expands them, and writing them back would freeze them), and the change
# is announced to the desktop so a new terminal sees it.
function Add-UserPath([string]$dir) {
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    if (-not $key) { $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment') }
    try {
        $raw = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $full = [IO.Path]::GetFullPath($dir).TrimEnd('\')
        foreach ($p in ($raw -split ';' | Where-Object { $_ })) {
            $q = [Environment]::ExpandEnvironmentVariables($p)
            try { $q = [IO.Path]::GetFullPath($q).TrimEnd('\') } catch { }
            if ($q -ieq $full) { return $false }
        }
        $new = if ($raw) { "$raw;$dir" } else { $dir }
        $key.SetValue('Path', $new, [Microsoft.Win32.RegistryValueKind]::ExpandString)
    } finally {
        $key.Close()
    }
    try {
        $sig = '[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);'
        $u = Add-Type -MemberDefinition $sig -Name 'Broadcast' -Namespace 'CigoInstall' -PassThru
        $out = [UIntPtr]::Zero
        $u::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$out) | Out-Null
    } catch { }
    return $true
}
try {
    if (Add-UserPath $bin) {
        Write-Host "added $bin to the user PATH; open a new terminal for the change to take effect"
    }
} catch {
    Write-Host "note: $bin is not on your PATH and could not be added ($($_.Exception.Message)); add it yourself"
}
