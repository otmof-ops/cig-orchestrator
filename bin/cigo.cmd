@echo off
@rem SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
@rem SPDX-License-Identifier: Apache-2.0
@rem cigo cmd shim: runs the .ps1 of the same name beside it, preferring pwsh
@rem (PowerShell 7) when it is on PATH and falling back to Windows PowerShell.
@rem %~dpn0.ps1 is "<this file's folder>\<this file's name>.ps1", so renaming
@rem the shim renames the .ps1 it looks for too.
setlocal
set "SCRIPT=%~dpn0.ps1"
where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 goto :pwsh
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
exit /b %ERRORLEVEL%
:pwsh
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
exit /b %ERRORLEVEL%
