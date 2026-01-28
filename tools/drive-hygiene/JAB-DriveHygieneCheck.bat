@echo off
:: JAB Drive Hygiene Check - Launcher
:: This batch file runs the PowerShell script without execution policy issues
:: Simply double-click this file to run the tool

title JAB Drive Hygiene Check
color 0B

echo.
echo  ============================================
echo   JAB Drive Hygiene Check
echo   https://jabsystems.io
echo  ============================================
echo.
echo  Starting disk analysis...
echo.

:: Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

:: Run the PowerShell script with bypass policy
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%JAB-DriveHygieneCheck.ps1"

:: Keep window open if there was an error
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo An error occurred. Press any key to exit...
    pause >nul
)
