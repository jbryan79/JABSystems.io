<#
.SYNOPSIS
    Fixes smart/fancy quotes in PowerShell scripts

.DESCRIPTION
    Replaces Unicode curly quotes with standard ASCII quotes that PowerShell recognizes
#>

param(
    [Parameter(Mandatory)]
    [string]$FilePath
)

$ErrorActionPreference = "Stop"

Write-Host "Processing: $FilePath" -ForegroundColor Cyan

# Read file
$content = Get-Content -Path $FilePath -Raw -Encoding UTF8

# Count replacements
$beforeLength = $content.Length
$originalContent = $content

# Replace fancy quotes with standard quotes
$content = $content -replace [char]0x201C, '"'   # Left double quotation mark → "
$content = $content -replace [char]0x201D, '"'   # Right double quotation mark → "
$content = $content -replace [char]0x2018, "'"   # Left single quotation mark → '
$content = $content -replace [char]0x2019, "'"   # Right single quotation mark → '
$content = $content -replace [char]0x2013, '-'   # En dash → -
$content = $content -replace [char]0x2014, '-'   # Em dash → -

if ($content -ne $originalContent) {
    Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
    Write-Host "✓ Fixed smart quotes" -ForegroundColor Green
    Write-Host "  Bytes changed: $(($beforeLength - $content.Length).ToString('N0'))" -ForegroundColor Gray
} else {
    Write-Host "✓ No smart quotes found" -ForegroundColor Yellow
}

# Validate syntax
Write-Host ""
Write-Host "Validating PowerShell syntax..." -ForegroundColor Cyan
$errors = @()
$tokens = @()
$parseErrors = @()

try {
    [void][System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $FilePath -Raw), [ref]$parseErrors)
    
    if ($parseErrors.Count -eq 0) {
        Write-Host "✓ Syntax is valid" -ForegroundColor Green
    } else {
        Write-Host "✗ Parse errors found:" -ForegroundColor Red
        foreach ($err in $parseErrors) {
            Write-Host "  Line $($err.Token.StartLine): $($err.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "✗ Validation failed: $_" -ForegroundColor Red
}