param(
    [string]$FilePath = "JAB-DriveHygieneCheck.ps1"
)

$ErrorActionPreference = "Stop"

Write-Host "Comprehensive File Fixer" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $FilePath)) {
    Write-Host "ERROR: File not found: $FilePath" -ForegroundColor Red
    exit 1
}

Write-Host "Reading: $FilePath" -ForegroundColor Yellow

# Read as raw bytes to handle encoding properly
$bytes = [System.IO.File]::ReadAllBytes($FilePath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

Write-Host "Original size: $($content.Length) characters" -ForegroundColor Gray

# Count and fix various problematic characters
$fixCount = 0

# Smart quotes
$replacements = @{
    [char]0x201C = '"'   # Left double quote
    [char]0x201D = '"'   # Right double quote
    [char]0x2018 = "'"   # Left single quote
    [char]0x2019 = "'"   # Right single quote
    [char]0x2013 = "-"   # En dash
    [char]0x2014 = "-"   # Em dash
    # Box drawing characters - replace with ASCII art
    [char]0x2554 = "+"   # ╔
    [char]0x2557 = "+"   # ╗
    [char]0x255A = "+"   # ╚
    [char]0x255D = "+"   # ╝
    [char]0x2551 = "|"   # ║
    [char]0x2550 = "="   # ═
    [char]0x2560 = "+"   # ╠
    [char]0x2563 = "+"   # ╣
    [char]0x250C = "+"   # ┌
    [char]0x2510 = "+"   # ┐
    [char]0x2514 = "+"   # └
    [char]0x2518 = "+"   # ┘
    [char]0x251C = "+"   # ├
    [char]0x2524 = "+"   # ┤
    [char]0x252C = "+"   # ┬
    [char]0x2534 = "+"   # ┴
    [char]0x253C = "+"   # ┼
    [char]0x2500 = "-"   # ─
    [char]0x2502 = "|"   # │
    [char]0x2588 = "#"   # █
    [char]0x2591 = "-"   # ░
}

foreach ($key in $replacements.Keys) {
    if ($content.Contains($key)) {
        $count = ($content.ToCharArray() | Where-Object { $_ -eq $key }).Count
        Write-Host "Replacing $count x $key with '$($replacements[$key])'" -ForegroundColor Yellow
        $content = $content.Replace($key, $replacements[$key])
        $fixCount += $count
    }
}

Write-Host ""
Write-Host "Total replacements: $fixCount" -ForegroundColor $(if ($fixCount -gt 0) { "Green" } else { "Gray" })

# Save with clean UTF-8 encoding (no BOM)
Write-Host "Saving fixed version..." -ForegroundColor Cyan
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($FilePath, $content, $utf8NoBom)
Write-Host "File saved successfully" -ForegroundColor Green

# Validate PowerShell syntax
Write-Host ""
Write-Host "Validating PowerShell syntax..." -ForegroundColor Cyan

try {
    $errors = @()
    $null = [System.Management.Automation.PSParser]::Tokenize(
        $content,
        [ref]$errors
    )

    if ($errors.Count -eq 0) {
        Write-Host "Syntax validation: PASSED" -ForegroundColor Green
        Write-Host ""
        Write-Host "File is clean and ready to use!" -ForegroundColor Green
    } else {
        Write-Host "Syntax validation: FAILED" -ForegroundColor Red
        Write-Host ""
        Write-Host "Errors found:" -ForegroundColor Red
        foreach ($err in $errors | Select-Object -First 5) {
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
