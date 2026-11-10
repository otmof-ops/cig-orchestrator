# SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
# SPDX-License-Identifier: Apache-2.0
# cigo is installed by ciginstaller now. This script is kept for one release so
# an old instruction fails with a way forward instead of a missing file; it
# installs nothing. To work on cigo from a checkout, run bin\cigo.cmd there
# (CONTRIBUTING.md, "Set up").
param(
    [string]$Prefix,
    [string]$Name
)
[Console]::Error.WriteLine('cigo is installed by ciginstaller now: ciginstaller install stick cigo')
[Console]::Error.WriteLine('')
[Console]::Error.WriteLine('No ciginstaller yet? How to get it:')
[Console]::Error.WriteLine('  https://github.com/otmof-ops/cig-installer#install')
[Console]::Error.WriteLine('It installs ciginstaller and asks what else you want; `ciginstaller install stick cigo` adds cigo.')
exit 1
