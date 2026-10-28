@echo off
@rem SPDX-FileCopyrightText: 2026 Jay Taylor (https://github.com/otmof-ops/cig-orchestrator)
@rem SPDX-License-Identifier: Apache-2.0
@rem cigo cmd shim: runs <name>.launch.ps1 beside it, preferring pwsh
@rem (PowerShell 7) when it is on PATH and falling back to Windows PowerShell.
@rem The launcher is not called cigo.ps1 on purpose: PowerShell would run
@rem that in-process before this shim, and it would eat the task's `--`,
@rem swallow stdin, leave the session in the project directory and need an
@rem execution policy. Through the shim none of that happens.
@rem %~dpn0 is "<this file's folder>\<this file's name>", so renaming the
@rem shim renames the launcher it looks for too.
setlocal
set "SCRIPT=%~dpn0.launch.ps1"
where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 goto :pwsh
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
exit /b %ERRORLEVEL%
:pwsh
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
exit /b %ERRORLEVEL%
