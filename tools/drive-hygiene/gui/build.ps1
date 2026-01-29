<#
.SYNOPSIS
    Build script for JAB Drive Hygiene GUI

.DESCRIPTION
    Builds the WPF GUI application as a self-contained single-file executable
#>

param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " JAB Drive Hygiene GUI Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get the project directory
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputDir = Join-Path $ProjectDir "..\build-gui"

Write-Host "Project Directory: $ProjectDir" -ForegroundColor Gray
Write-Host "Output Directory:  $OutputDir" -ForegroundColor Gray
Write-Host "Configuration:     $Configuration" -ForegroundColor Gray
Write-Host ""

# Clean previous builds
if (Test-Path $OutputDir) {
    Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
    Remove-Item $OutputDir -Recurse -Force
}

# Build the application
Write-Host "Building application..." -ForegroundColor Cyan
Set-Location $ProjectDir

dotnet publish `
    -c $Configuration `
    -r win-x64 `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:PublishReadyToRun=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -o $OutputDir

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Output files:" -ForegroundColor Cyan
Get-ChildItem $OutputDir -Filter "*.exe" | ForEach-Object {
    Write-Host "  - $($_.Name) ($([math]::Round($_.Length / 1MB, 2)) MB)" -ForegroundColor White
}

Write-Host ""
Write-Host "Build artifacts are in: $OutputDir" -ForegroundColor Green
Write-Host ""
