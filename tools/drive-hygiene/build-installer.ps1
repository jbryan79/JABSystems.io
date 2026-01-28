<#
.SYNOPSIS
    Build script for JAB Drive Hygiene Check - creates both EXE and installer

.DESCRIPTION
    This script:
    1. Fixes smart quotes in the PowerShell script
    2. Compiles the script to a standalone .exe using ps2exe
    3. Creates the NSIS installer package
    4. Signs the installer (if certificate available)

.NOTES
    Requirements:
    - PowerShell 5.1 or later
    - ps2exe module (auto-installed)
    - NSIS compiler (must be installed manually)

.EXAMPLE
    .\build-installer.ps1
    Creates the complete distribution package
#>

[CmdletBinding()]
param(
    [switch]$SkipExe,
    [switch]$SkipInstaller,
    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$Version = "1.0.0"
$Year = (Get-Date).Year

$ScriptRoot = $PSScriptRoot
$ScriptPath = Join-Path $ScriptRoot "JAB-DriveHygieneCheck.ps1"
$BatPath = Join-Path $ScriptRoot "JAB-DriveHygieneCheck.bat"
$ReadmePath = Join-Path $ScriptRoot "README.md"
$IconPath = Join-Path $ScriptRoot "jab-icon.ico"

$BuildDir = Join-Path $ScriptRoot "build"
$ExePath = Join-Path $BuildDir "JAB-DriveHygieneCheck.exe"
$InstallerPath = Join-Path $BuildDir "JAB-DriveHygieneCheck-${Version}-installer.exe"
$NsisScriptPath = Join-Path $ScriptRoot "JAB-DriveHygieneCheck-Installer.nsi"

# NSIS Compiler Paths (check common locations)
$NsisPath = @(
    "F:\Program Files\NSIS\makensis.exe",
    "C:\Program Files (x86)\NSIS\makensis.exe",
    "C:\Program Files\NSIS\makensis.exe",
    "${env:ProgramFiles(x86)}\NSIS\makensis.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

# ============================================================================
# DISPLAY HEADER
# ============================================================================

Write-Host ""
Write-Host "  ========================================================================" -ForegroundColor Cyan
Write-Host "  JAB Drive Hygiene Check - Build & Installer Script" -ForegroundColor Cyan
Write-Host "  Version $Version" -ForegroundColor Cyan
Write-Host "  ========================================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# STEP 1: FIX SMART QUOTES
# ============================================================================

Write-Host "  [1/4] Fixing smart quotes in PowerShell script..." -ForegroundColor Yellow

if (-not (Test-Path $ScriptPath)) {
    Write-Host "    ERROR: Script not found: $ScriptPath" -ForegroundColor Red
    exit 1
}

$content = Get-Content -Path $ScriptPath -Raw -Encoding UTF8
$originalContent = $content

# Replace fancy quotes with standard quotes
$content = $content -replace [char]0x201C, '"'   # Left double quotation mark
$content = $content -replace [char]0x201D, '"'   # Right double quotation mark
$content = $content -replace [char]0x2018, "'"   # Left single quotation mark
$content = $content -replace [char]0x2019, "'"   # Right single quotation mark

if ($content -ne $originalContent) {
    Set-Content -Path $ScriptPath -Value $content -Encoding UTF8 -NoNewline
    Write-Host "    [OK] Smart quotes fixed" -ForegroundColor Green
} else {
    Write-Host "    [OK] No smart quotes found" -ForegroundColor Green
}

# ============================================================================
# STEP 2: CREATE BUILD DIRECTORY
# ============================================================================

Write-Host ""
Write-Host "  [2/4] Preparing build environment..." -ForegroundColor Yellow

if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
    Write-Host "    [OK] Build directory created" -ForegroundColor Green
} else {
    Write-Host "    [OK] Build directory exists" -ForegroundColor Green
}

# ============================================================================
# STEP 3: BUILD EXECUTABLE
# ============================================================================

if (-not $SkipExe) {
    Write-Host ""
    Write-Host "  [3/4] Compiling executable..." -ForegroundColor Yellow

    # Check for ps2exe module
    $ps2exeModule = Get-Module -ListAvailable -Name ps2exe

    if (-not $ps2exeModule) {
        Write-Host "    Installing ps2exe module..." -ForegroundColor Cyan
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction SilentlyContinue | Out-Null
            Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
            Write-Host "    [OK] ps2exe installed" -ForegroundColor Green
        }
        catch {
            Write-Host "    ERROR: Failed to install ps2exe: $_" -ForegroundColor Red
            exit 1
        }
    }

    Import-Module ps2exe -ErrorAction Stop

    # Compile to EXE
    try {
        $compileParams = @{
            inputFile    = $ScriptPath
            outputFile   = $ExePath
            noConsole    = $false
            requireAdmin = $false
            title        = "JAB Drive Hygiene Check"
            description  = "Safe, read-only disk inspection and cleanup utility for Windows"
            company      = "JAB Systems"
            product      = "JAB Drive Hygiene Check"
            copyright    = "(c) $Year JAB Systems. All rights reserved."
            version      = "$Version.0"
        }

        if (Test-Path $IconPath) {
            $compileParams.iconFile = $IconPath
        }

        Invoke-ps2exe @compileParams
        Write-Host "    [OK] Executable compiled successfully" -ForegroundColor Green
        $exeSize = [math]::Round((Get-Item $ExePath).Length / 1MB, 2)
        Write-Host "    Size: $exeSize MB" -ForegroundColor Gray
    }
    catch {
        Write-Host "    ERROR: Compilation failed: $_" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# STEP 4: CREATE INSTALLER
# ============================================================================

if (-not $SkipInstaller) {
    Write-Host ""
    Write-Host "  [4/4] Building NSIS installer..." -ForegroundColor Yellow

    if (-not $NsisPath) {
        Write-Host "    ERROR: NSIS compiler not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "    Install NSIS from: https://nsis.sourceforge.io/" -ForegroundColor Yellow
        Write-Host "    Then run this script again." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }

    if (-not (Test-Path $NsisScriptPath)) {
        Write-Host "    ERROR: NSIS script not found: $NsisScriptPath" -ForegroundColor Red
        exit 1
    }

    # Copy files to build directory for installer
    if ((Split-Path $ExePath -Parent) -ne $BuildDir) {
        Copy-Item -Path $ExePath -Destination $BuildDir -Force
    }
    Copy-Item -Path $BatPath -Destination $BuildDir -Force
    Copy-Item -Path $ScriptPath -Destination $BuildDir -Force
    Copy-Item -Path $ReadmePath -Destination $BuildDir -Force

    # Create LICENSE file if not exists
    $LicensePath = Join-Path $BuildDir "LICENSE.txt"
    if (-not (Test-Path $LicensePath)) {
        $licenseContent = @"
MIT License

Copyright (c) $Year JAB Systems

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"@
        Set-Content -Path $LicensePath -Value $licenseContent -Encoding UTF8
    }

    try {
        # Build installer
        & $NsisPath /V4 /DOUTFILE="$InstallerPath" $NsisScriptPath

        if (Test-Path $InstallerPath) {
            $installerSize = [math]::Round((Get-Item $InstallerPath).Length / 1MB, 2)
            Write-Host "    [OK] Installer created successfully" -ForegroundColor Green
            Write-Host "    Size: $installerSize MB" -ForegroundColor Gray
        } else {
            Write-Host "    ERROR: Installer file was not created" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "    ERROR: Installer build failed: $_" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host ""
Write-Host "  ========================================================================" -ForegroundColor Cyan
Write-Host "  BUILD COMPLETE" -ForegroundColor Cyan
Write-Host "  ========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Output Files:" -ForegroundColor White

if (Test-Path $ExePath) {
    Write-Host "    OK: $ExePath" -ForegroundColor Green
}

if (Test-Path $InstallerPath) {
    Write-Host "    OK: $InstallerPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "  Next Steps:" -ForegroundColor White
Write-Host "    1. Test the installer: $InstallerPath" -ForegroundColor Gray
Write-Host "    2. Upload to release hosting or distribution platform" -ForegroundColor Gray
Write-Host "    3. Share download link with users" -ForegroundColor Gray
Write-Host ""
