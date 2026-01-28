<p align="center">
  <img src="../../assets/jab-logo.png" alt="JAB Systems" width="80">
</p>

<h1 align="center">JAB Drive Hygiene Check</h1>
<h3 align="center">Developer & Technical Guide</h3>

<p align="center">
  <a href="#architecture">Architecture</a> •
  <a href="#api-reference">API Reference</a> •
  <a href="#development">Development</a> •
  <a href="#building">Building</a> •
  <a href="#contributing">Contributing</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Language-PowerShell%205.1+-blue?style=flat-square" alt="Language">
  <img src="https://img.shields.io/badge/Target-Windows%2010%2F11-0078D6?style=flat-square" alt="Target">
  <img src="https://img.shields.io/badge/Dependencies-None-success?style=flat-square" alt="Dependencies">
</p>

---

## Overview

JAB Drive Hygiene Check is a PowerShell-based disk inspection utility designed with **transparency** and **safety** as core principles. This guide covers the technical architecture, API usage, and development guidelines.

### Design Philosophy

| Principle | Implementation |
|-----------|----------------|
| **Read-Only Default** | All inspection functions are non-destructive |
| **Native APIs Only** | Uses built-in Windows WMI/CIM and Storage cmdlets |
| **Zero Dependencies** | Single-file script, no external modules required |
| **Graceful Degradation** | Works with limited features when admin rights unavailable |
| **User Confirmation** | Any destructive action requires explicit approval |

---

## Project Structure

```
tools/drive-hygiene/
│
├── JAB-DriveHygieneCheck.ps1    # Main application script
├── JAB-DriveHygieneCheck.bat    # Windows launcher (bypasses execution policy)
├── build-exe.ps1                # Compilation script for .exe distribution
│
├── README.md                    # User documentation
└── CLAUDE.md                    # This file (technical documentation)
```

---

## Architecture

### Module Organization

The script is organized into logical sections:

```
┌─────────────────────────────────────────────────────────────────┐
│                     JAB-DriveHygieneCheck.ps1                   │
├─────────────────────────────────────────────────────────────────┤
│  CONFIGURATION                                                  │
│  └── Script variables, safe cleanup categories                  │
├─────────────────────────────────────────────────────────────────┤
│  HELPER FUNCTIONS                                               │
│  ├── Write-Header, Write-SectionHeader, Write-SubHeader        │
│  ├── Format-ByteSize, Write-StatusLine                         │
│  └── Test-AdminPrivileges                                       │
├─────────────────────────────────────────────────────────────────┤
│  DISK INSPECTION                                                │
│  ├── Get-PhysicalDiskInfo      → Physical drives               │
│  ├── Get-SMARTStatus           → Health & reliability          │
│  └── Get-LogicalDiskInfo       → Volumes & partitions          │
├─────────────────────────────────────────────────────────────────┤
│  SSD FUNCTIONS                                                  │
│  ├── Get-TrimStatus            → TRIM enabled/disabled         │
│  └── Get-OptimizationStatus    → Defrag/optimization state     │
├─────────────────────────────────────────────────────────────────┤
│  USAGE ANALYSIS                                                 │
│  ├── Get-FolderSize            → Calculate directory size      │
│  ├── Get-TempFilesSummary      → Temp folder analysis          │
│  ├── Get-SystemCachesSummary   → Windows caches                │
│  ├── Get-RecycleBinSize        → Recycle bin per drive         │
│  ├── Get-BrowserCachesSummary  → Chrome/Edge/Firefox           │
│  └── Get-UsageBreakdown        → Aggregated breakdown          │
├─────────────────────────────────────────────────────────────────┤
│  DISPLAY FUNCTIONS                                              │
│  ├── Show-PhysicalDisks, Show-SMARTStatus                      │
│  ├── Show-Volumes, Show-TrimStatus                             │
│  └── Show-UsageBreakdown                                        │
├─────────────────────────────────────────────────────────────────┤
│  CLEANUP FUNCTIONS                                              │
│  └── Invoke-SafeDiskCleanup    → Launch cleanmgr.exe           │
├─────────────────────────────────────────────────────────────────┤
│  REPORT GENERATION                                              │
│  ├── Export-HTMLReport         → Styled HTML output            │
│  └── Export-TextReport         → Plain text output             │
├─────────────────────────────────────────────────────────────────┤
│  MAIN EXECUTION                                                 │
│  ├── Show-MainMenu             → Interactive menu loop         │
│  ├── Invoke-FullScan           → Complete system scan          │
│  └── Start-InteractiveMode     → Entry point for interactive   │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
User Input → Parameter Parsing → Mode Selection
                                       │
                    ┌──────────────────┼──────────────────┐
                    ↓                  ↓                  ↓
              Interactive         QuickScan          ExportOnly
                    │                  │                  │
                    └────────┬─────────┴──────────────────┘
                             ↓
                    Data Collection Layer
                    ├── Get-PhysicalDiskInfo()
                    ├── Get-SMARTStatus()
                    ├── Get-LogicalDiskInfo()
                    ├── Get-TrimStatus()
                    └── Get-UsageBreakdown()
                             │
              ┌──────────────┼──────────────┐
              ↓              ↓              ↓
         Console        HTML Report    Text Report
         Output          Export         Export
```

---

## API Reference

### Windows APIs Used

#### Storage Cmdlets (Primary)

```powershell
# Physical disk information and SMART status
Get-PhysicalDisk
# Returns: DeviceId, FriendlyName, MediaType, BusType, HealthStatus, Size

# Reliability counters (requires admin)
Get-StorageReliabilityCounter -PhysicalDisk $disk
# Returns: Temperature, ReadErrorsTotal, WriteErrorsTotal, PowerOnHours, Wear

# Volume information
Get-Volume
# Returns: DriveLetter, FileSystemType, Size, SizeRemaining
```

#### WMI/CIM Classes (Fallback)

```powershell
# Physical drives (fallback when Storage cmdlets unavailable)
Get-CimInstance -ClassName Win32_DiskDrive
# Returns: Index, Model, InterfaceType, MediaType, Size, Status

# Logical disks / partitions
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
# Returns: DeviceID, VolumeName, FileSystem, Size, FreeSpace
```

#### External Commands

| Command | Purpose | Admin Required |
|---------|---------|----------------|
| `fsutil behavior query DisableDeleteNotify` | Check TRIM status | No |
| `cleanmgr.exe /D <drive>` | Launch Disk Cleanup | No |

---

## Development

### Code Style Guidelines

#### Function Naming

Use **approved PowerShell verbs** with PascalCase:

| Verb | Use For |
|------|---------|
| `Get-` | Retrieve data without side effects |
| `Set-` | Modify configuration |
| `Test-` | Return boolean result |
| `Invoke-` | Execute an action |
| `Export-` | Output to file |
| `Show-` | Display to console |
| `Write-` | Console output helpers |
| `Format-` | Data transformation |

#### Function Template

```powershell
function Get-ExampleData {
    <#
    .SYNOPSIS
        Brief one-line description

    .DESCRIPTION
        Detailed explanation of what the function does

    .PARAMETER ParameterName
        Description of the parameter

    .EXAMPLE
        Get-ExampleData -ParameterName "value"

        Description of what this example does

    .OUTPUTS
        [PSCustomObject] Description of output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ParameterName
    )

    try {
        # Implementation
        $result = [PSCustomObject]@{
            Property1 = "Value"
            Property2 = 123
        }
        return $result
    }
    catch {
        Write-Verbose "Error in Get-ExampleData: $_"
        return $null
    }
}
```

### Safety Requirements

#### MUST DO

- Use `[CmdletBinding()]` on all functions
- Include comment-based help (`.SYNOPSIS`)
- Use `try/catch` with `-ErrorAction SilentlyContinue` for graceful degradation
- Return `$null` or empty collections on failure, never throw to user
- Confirm any destructive action with user
- Test with and without admin privileges

#### MUST NOT

- Modify the Windows Registry
- Install drivers or kernel components
- Create background services or scheduled tasks
- Delete files without explicit user confirmation
- Transmit data over the network
- Store persistent state

### Error Handling Pattern

```powershell
function Get-DiskData {
    [CmdletBinding()]
    param()

    $results = @()

    try {
        # Primary method
        $data = Get-PhysicalDisk -ErrorAction Stop
        # Process $data...
    }
    catch {
        Write-Verbose "Primary method failed: $_"

        try {
            # Fallback method
            $data = Get-CimInstance Win32_DiskDrive -ErrorAction Stop
            # Process $data...
        }
        catch {
            Write-Verbose "Fallback method failed: $_"
            # Return empty, don't throw
        }
    }

    return $results
}
```

---

## Building

### Distribution Options

#### Option 1: Script + Launcher (Default)

Distribute these files together:
- `JAB-DriveHygieneCheck.ps1` — Main script
- `JAB-DriveHygieneCheck.bat` — Double-click launcher

#### Option 2: Compiled Executable

Use `ps2exe` to create a standalone `.exe`:

```powershell
# Install ps2exe (one-time)
Install-Module -Name ps2exe -Scope CurrentUser

# Run the build script
.\build-exe.ps1
```

Or manually:

```powershell
Invoke-ps2exe -inputFile "JAB-DriveHygieneCheck.ps1" `
              -outputFile "JAB-DriveHygieneCheck.exe" `
              -noConsole:$false `
              -title "JAB Drive Hygiene Check" `
              -company "JAB Systems" `
              -version "1.0.0.0"
```

### Code Signing (Enterprise)

For enterprise distribution, sign the script:

```powershell
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert
Set-AuthenticodeSignature -FilePath ".\JAB-DriveHygieneCheck.ps1" -Certificate $cert
```

---

## Testing

### Test Matrix

| Scenario | Windows 10 | Windows 11 |
|----------|------------|------------|
| Standard user | ✓ | ✓ |
| Administrator | ✓ | ✓ |
| Single HDD | ✓ | ✓ |
| Single SSD (SATA) | ✓ | ✓ |
| Single NVMe | ✓ | ✓ |
| Multiple drives | ✓ | ✓ |
| Low disk space (<1GB) | ✓ | ✓ |
| BitLocker encrypted | ✓ | ✓ |

### Test Commands

```powershell
# Interactive mode
.\JAB-DriveHygieneCheck.ps1

# Quick scan (non-interactive)
.\JAB-DriveHygieneCheck.ps1 -QuickScan

# With verbose output
.\JAB-DriveHygieneCheck.ps1 -QuickScan -Verbose

# Export HTML report
.\JAB-DriveHygieneCheck.ps1 -ExportReport -ReportFormat HTML

# Export text report
.\JAB-DriveHygieneCheck.ps1 -ExportReport -ReportFormat Text

# Full options
.\JAB-DriveHygieneCheck.ps1 -QuickScan -ExportReport -OutputPath "C:\Reports" -ReportFormat HTML -Verbose
```

---

## Safe Cleanup Categories

### Included (Pre-vetted Safe)

```powershell
$Script:SafeCleanupCategories = @(
    "Temporary Files"
    "Temporary Internet Files"
    "Thumbnails"
    "Delivery Optimization Files"
    "Windows Update Cleanup"
    "Windows Upgrade Log Files"
    "Downloaded Program Files"
    "Recycle Bin"
)
```

### Excluded (Risk of Data Loss)

| Category | Reason |
|----------|--------|
| System Restore Points | User may need for recovery |
| Previous Windows Installations | User may need to roll back |
| Device Driver Packages | May break hardware functionality |
| Windows Defender files | Security implications |
| Debug dump files | May be needed for diagnostics |

---

## Versioning

**Format:** `MAJOR.MINOR.PATCH`

| Component | When to Increment |
|-----------|-------------------|
| MAJOR | Breaking changes, significant rewrites |
| MINOR | New features, backward compatible |
| PATCH | Bug fixes, minor improvements |

Update in script header:
```powershell
$Script:Version = "1.0.0"
```

---

## Changelog

### v1.0.0 — Initial Release

**Features:**
- Physical disk enumeration with SMART health status
- Volume space analysis with visual progress bars
- SSD TRIM status detection
- Usage breakdown by category (temp, caches, browser data)
- Safe cleanup launcher (Windows Disk Cleanup integration)
- HTML and text report export
- Interactive menu system
- Command-line quick scan mode
- Graceful degradation without admin rights

**Safety:**
- Read-only by default
- No registry modifications
- No network connections
- No persistent state
- User confirmation for all cleanup actions

---

## Support

| Channel | Contact |
|---------|---------|
| **Website** | [jabsystems.io](https://jabsystems.io) |
| **Email** | info@jabsystems.io |
| **Issues** | Contact via email |

---

<p align="center">
  <sub>Built by <a href="https://jabsystems.io">JAB Systems</a> — Enterprise tools built by operators, for operators.</sub>
</p>
