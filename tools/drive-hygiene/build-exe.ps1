<#
.SYNOPSIS
    Build script to compile JAB Drive Hygiene Check into a branded executable

.DESCRIPTION
    This script:
    1. Compiles the PowerShell script into a standalone .exe with your branding
    2. Creates a ZIP package containing .exe, .bat, .ps1, and README

    The resulting .exe will have:
    - Your logo as the icon
    - JAB Systems in the file properties
    - Version, description, and copyright information

.NOTES
    Requirements:
    - PowerShell 5.1 or later
    - Internet connection (to install ps2exe if not present)
    - favicon.ico in ../../assets/ folder

.EXAMPLE
    .\build-exe.ps1
    Creates JAB-DriveHygieneCheck.exe and JAB-DriveHygieneCheck-v1.0.0.zip
#>

[CmdletBinding()]
param(
    [switch]$SkipZip
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$Version = "1.0.0"
$Year = (Get-Date).Year

$ExeMetadata = @{
    title       = "JAB Drive Hygiene Check"
    description = "Safe, read-only disk inspection and cleanup utility for Windows"
    company     = "JAB Systems"
    product     = "JAB Drive Hygiene Check"
    copyright   = "(c) $Year JAB Systems. All rights reserved."
    trademark   = "JAB Systems"
    version     = "$Version.0"
}

# ============================================================================
# DISPLAY HEADER
# ============================================================================

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║         JAB Drive Hygiene Check - Build Script                ║" -ForegroundColor Cyan
Write-Host "  ║                     Version $Version                              ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# SET PATHS
# ============================================================================

$ScriptRoot = $PSScriptRoot
$ScriptPath = Join-Path $ScriptRoot "JAB-DriveHygieneCheck.ps1"
$BatPath = Join-Path $ScriptRoot "JAB-DriveHygieneCheck.bat"
$ExePath = Join-Path $ScriptRoot "JAB-DriveHygieneCheck.exe"
$ReadmePath = Join-Path $ScriptRoot "README.md"
$IconPath = Join-Path $ScriptRoot "..\..\assets\favicon.ico"
$ZipPath = Join-Path $ScriptRoot "JAB-DriveHygieneCheck-v$Version.zip"

# ============================================================================
# VERIFY SOURCE FILES
# ============================================================================

Write-Host "  Checking source files..." -ForegroundColor Yellow

$requiredFiles = @(
    @{ Path = $ScriptPath; Name = "PowerShell script" }
    @{ Path = $BatPath; Name = "Batch launcher" }
    @{ Path = $ReadmePath; Name = "README" }
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (Test-Path $file.Path) {
        Write-Host "    [OK] $($file.Name)" -ForegroundColor Green
    } else {
        Write-Host "    [MISSING] $($file.Name): $($file.Path)" -ForegroundColor Red
        $missingFiles += $file.Name
    }
}

# Check icon (optional but recommended)
if (Test-Path $IconPath) {
    Write-Host "    [OK] Custom icon" -ForegroundColor Green
    $hasIcon = $true
} else {
    Write-Host "    [SKIP] Custom icon not found (will use default)" -ForegroundColor Yellow
    $hasIcon = $false
}

if ($missingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "  Error: Missing required files. Cannot continue." -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# INSTALL PS2EXE IF NEEDED
# ============================================================================

$ps2exeModule = Get-Module -ListAvailable -Name ps2exe

if (-not $ps2exeModule) {
    Write-Host "  Installing ps2exe module..." -ForegroundColor Yellow

    try {
        # Install NuGet provider if needed
        $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction SilentlyContinue

        # Install ps2exe
        Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
        Write-Host "    ps2exe installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "  Failed to install ps2exe automatically." -ForegroundColor Red
        Write-Host ""
        Write-Host "  Manual installation steps:" -ForegroundColor Yellow
        Write-Host "    1. Open PowerShell as Administrator" -ForegroundColor Gray
        Write-Host "    2. Run: Install-Module -Name ps2exe -Force" -ForegroundColor Gray
        Write-Host "    3. Run this script again" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
}

Import-Module ps2exe -ErrorAction Stop

# ============================================================================
# COMPILE TO EXE
# ============================================================================

Write-Host "  Compiling executable..." -ForegroundColor Yellow
Write-Host "    Source: $ScriptPath" -ForegroundColor Gray
Write-Host "    Output: $ExePath" -ForegroundColor Gray
Write-Host ""

# Build compile parameters
$compileParams = @{
    inputFile    = $ScriptPath
    outputFile   = $ExePath
    noConsole    = $false  # Keep console for interactive mode
    requireAdmin = $false  # Don't force admin (but recommend it)
    title        = $ExeMetadata.title
    description  = $ExeMetadata.description
    company      = $ExeMetadata.company
    product      = $ExeMetadata.product
    copyright    = $ExeMetadata.copyright
    trademark    = $ExeMetadata.trademark
    version      = $ExeMetadata.version
}

# Add icon if available
if ($hasIcon) {
    $compileParams.iconFile = $IconPath
    Write-Host "    Using custom icon: $IconPath" -ForegroundColor Gray
}

try {
    Invoke-ps2exe @compileParams

    if (Test-Path $ExePath) {
        $exeSize = [math]::Round((Get-Item $ExePath).Length / 1KB, 2)
        Write-Host ""
        Write-Host "    Executable created successfully!" -ForegroundColor Green
        Write-Host "    Size: $exeSize KB" -ForegroundColor Gray
    } else {
        throw "Executable was not created"
    }
}
catch {
    Write-Host ""
    Write-Host "  Compilation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# CREATE ZIP PACKAGE
# ============================================================================

if (-not $SkipZip) {
    Write-Host "  Creating distribution package..." -ForegroundColor Yellow
    Write-Host "    Output: $ZipPath" -ForegroundColor Gray

    # Remove existing zip if present
    if (Test-Path $ZipPath) {
        Remove-Item $ZipPath -Force
    }

    # Files to include in the package
    $filesToPackage = @(
        $ExePath
        $BatPath
        $ScriptPath
        $ReadmePath
    )

    try {
        # Create the zip
        Compress-Archive -Path $filesToPackage -DestinationPath $ZipPath -CompressionLevel Optimal

        if (Test-Path $ZipPath) {
            $zipSize = [math]::Round((Get-Item $ZipPath).Length / 1KB, 2)
            Write-Host ""
            Write-Host "    Package created successfully!" -ForegroundColor Green
            Write-Host "    Size: $zipSize KB" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "    Warning: Failed to create ZIP package: $_" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "  ═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                         BUILD COMPLETE" -ForegroundColor Green
Write-Host "  ═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Output Files:" -ForegroundColor White

if (Test-Path $ExePath) {
    Write-Host "    - $ExePath" -ForegroundColor Gray
}
if (Test-Path $ZipPath) {
    Write-Host "    - $ZipPath" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  File Properties (right-click .exe > Properties > Details):" -ForegroundColor White
Write-Host "    Product name:  $($ExeMetadata.product)" -ForegroundColor Gray
Write-Host "    Company:       $($ExeMetadata.company)" -ForegroundColor Gray
Write-Host "    Description:   $($ExeMetadata.description)" -ForegroundColor Gray
Write-Host "    Copyright:     $($ExeMetadata.copyright)" -ForegroundColor Gray
Write-Host "    Version:       $($ExeMetadata.version)" -ForegroundColor Gray
Write-Host ""
Write-Host "  The ZIP package contains:" -ForegroundColor White
Write-Host "    - JAB-DriveHygieneCheck.exe  (double-click to run)" -ForegroundColor Gray
Write-Host "    - JAB-DriveHygieneCheck.bat  (alternative launcher)" -ForegroundColor Gray
Write-Host "    - JAB-DriveHygieneCheck.ps1  (source script)" -ForegroundColor Gray
Write-Host "    - README.md                   (documentation)" -ForegroundColor Gray
Write-Host ""
