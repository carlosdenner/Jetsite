@echo off
REM Jetsite - GitHub Template Repository Forker (Windows Batch Wrapper)
REM This batch file launches the PowerShell script for Windows users

echo Starting Jetsite...
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell is available'" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell is not available on this system.
    echo Please use Windows 10/11 or install PowerShell Core.
    pause
    exit /b 1
)

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0fork_template_repo.ps1"

REM Check if the PowerShell script ran successfully
if %errorlevel% neq 0 (
    echo.
    echo The script encountered an error.
    pause
)
