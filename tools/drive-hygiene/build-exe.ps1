<#
.SYNOPSIS
    Build script to compile JAB Drive Hygiene Check into an executable

.DESCRIPTION
    This script uses ps2exe to convert the PowerShell script into a standalone
    Windows executable (.exe) that users can double-click to run.

.NOTES
    Requirements:
    - PowerShell 5.1 or later
    - Internet connection (to install ps2exe if not present)

.EXAMPLE
    .\build-exe.ps1
    Compiles JAB-DriveHygieneCheck.ps1 into JAB-DriveHygieneCheck.exe
#>

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  JAB Drive Hygiene Check - Build Script" -ForegroundColor Cyan
Write-Host "  =======================================" -ForegroundColor Cyan
Write-Host ""

# Check if ps2exe is installed
$ps2exeModule = Get-Module -ListAvailable -Name ps2exe

if (-not $ps2exeModule) {
    Write-Host "  Installing ps2exe module..." -ForegroundColor Yellow

    try {
        # Try to install NuGet provider first
        $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction SilentlyContinue

        # Install ps2exe
        Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
        Write-Host "  ps2exe installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to install ps2exe automatically." -ForegroundColor Red
        Write-Host ""
        Write-Host "  Please install manually:" -ForegroundColor Yellow
        Write-Host "  1. Open PowerShell as Administrator" -ForegroundColor Gray
        Write-Host "  2. Run: Install-Module -Name ps2exe -Force" -ForegroundColor Gray
        Write-Host "  3. Run this script again" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
}

# Import the module
Import-Module ps2exe

# Set paths
$scriptPath = Join-Path $PSScriptRoot "JAB-DriveHygieneCheck.ps1"
$exePath = Join-Path $PSScriptRoot "JAB-DriveHygieneCheck.exe"
$iconPath = Join-Path $PSScriptRoot "..\..\assets\favicon.ico"

# Check if source script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "  Error: Source script not found at $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "  Compiling PowerShell script to executable..." -ForegroundColor Yellow
Write-Host "  Source: $scriptPath" -ForegroundColor Gray
Write-Host "  Output: $exePath" -ForegroundColor Gray
Write-Host ""

# Compile parameters
$compileParams = @{
    inputFile = $scriptPath
    outputFile = $exePath
    noConsole = $false  # Keep console window for interactive mode
    requireAdmin = $false  # Don't require admin (but recommend it)
    title = "JAB Drive Hygiene Check"
    description = "Safe, read-only disk inspection and cleanup utility"
    company = "JAB Systems"
    product = "JAB Drive Hygiene Check"
    copyright = "(c) 2024 JAB Systems"
    version = "1.0.0.0"
}

# Add icon if it exists
if (Test-Path $iconPath) {
    $compileParams.iconFile = $iconPath
    Write-Host "  Using custom icon: $iconPath" -ForegroundColor Gray
}

try {
    # Run the compilation
    Invoke-ps2exe @compileParams

    Write-Host ""
    Write-Host "  Build successful!" -ForegroundColor Green
    Write-Host "  Executable created: $exePath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  File size: $([math]::Round((Get-Item $exePath).Length / 1KB, 2)) KB" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "  Build failed: $_" -ForegroundColor Red
    exit 1
}
