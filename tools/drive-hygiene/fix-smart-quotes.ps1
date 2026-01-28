param(
    [string]$FilePath = "JAB-DriveHygieneCheck.ps1"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Smart Quote Fixer" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $FilePath)) {
    Write-Host "ERROR: File not found: $FilePath" -ForegroundColor Red
    exit 1
}

Write-Host "Reading: $FilePath" -ForegroundColor Yellow

# Read as bytes to catch encoding issues
$bytes = [System.IO.File]::ReadAllBytes($FilePath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

Write-Host "Original size: $($content.Length) characters" -ForegroundColor Gray

# Find all problematic characters
$problematicChars = @(
    @{ Char = [char]0x201C; Name = "Left double quote"; Replace = '"' },
    @{ Char = [char]0x201D; Name = "Right double quote"; Replace = '"' },
    @{ Char = [char]0x2018; Name = "Left single quote"; Replace = "'" },
    @{ Char = [char]0x2019; Name = "Right single quote"; Replace = "'" },
    @{ Char = [char]0x2013; Name = "En dash"; Replace = "-" },
    @{ Char = [char]0x2014; Name = "Em dash"; Replace = "-" }
)

$foundIssues = $false
$originalContent = $content

foreach ($item in $problematicChars) {
    if ($content.Contains($item.Char)) {
        $count = ($content.ToCharArray() | Where-Object { $_ -eq $item.Char }).Count
        Write-Host "Found $count x $($item.Name)" -ForegroundColor Yellow
        $content = $content.Replace($item.Char, $item.Replace)
        $foundIssues = $true
    }
}

if ($foundIssues) {
    Write-Host ""
    Write-Host "Writing fixed version..." -ForegroundColor Cyan
    [System.IO.File]::WriteAllBytes($FilePath, [System.Text.Encoding]::UTF8.GetBytes($content))
    Write-Host "File updated successfully" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "No problematic characters found - file is clean" -ForegroundColor Green
}

# Validate PowerShell syntax
Write-Host ""
Write-Host "Validating PowerShell syntax..." -ForegroundColor Cyan

try {
    $tokens = @()
    $errors = @()
    $null = [System.Management.Automation.PSParser]::Tokenize(
        (Get-Content -Path $FilePath -Raw),
        [ref]$errors
    )
    
    if ($errors.Count -eq 0) {
        Write-Host "Syntax validation: PASSED" -ForegroundColor Green
    } else {
        Write-Host "Syntax validation: FAILED" -ForegroundColor Red
        Write-Host ""
        Write-Host "Errors found:" -ForegroundColor Red
        foreach ($err in $errors) {
            Write-Host "  Line $($err.Token.StartLine): $($err.Message)" -ForegroundColor Red
        }
        exit 1
    }
}
catch {
    Write-Host "Syntax validation: ERROR - $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All checks passed!" -ForegroundColor Green
Write-Host ""
