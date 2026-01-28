# JAB Drive Hygiene Check - Developer Guide

## Overview

PowerShell-based disk inspection and safe cleanup utility for Windows 10/11. This tool provides read-only disk analysis and optionally invokes native Windows cleanup utilities with pre-vetted safe categories.

## Project Structure

```
tools/drive-hygiene/
├── index.html                    # Website detail page
├── README.md                     # User documentation
├── CLAUDE.md                     # This file (developer guide)
└── JAB-DriveHygieneCheck.ps1     # Main PowerShell script
```

## Technology Stack

- **Language**: PowerShell 5.1+
- **Target OS**: Windows 10 (1903+), Windows 11
- **Dependencies**: None (uses built-in Windows APIs)
- **Distribution**: Single .ps1 file

## Code Architecture

### Script Structure

```
JAB-DriveHygieneCheck.ps1
├── Script Header & Parameters
├── Configuration
│   └── $Script:SafeCleanupCategories
├── Helper Functions
│   ├── Write-Header
│   ├── Write-SectionHeader
│   ├── Write-SubHeader
│   ├── Format-ByteSize
│   ├── Write-StatusLine
│   └── Test-AdminPrivileges
├── Disk Inspection Functions
│   ├── Get-PhysicalDiskInfo
│   ├── Get-SMARTStatus
│   └── Get-LogicalDiskInfo
├── SSD Functions
│   ├── Get-TrimStatus
│   └── Get-OptimizationStatus
├── Usage Analysis Functions
│   ├── Get-FolderSize
│   ├── Get-TempFilesSummary
│   ├── Get-SystemCachesSummary
│   ├── Get-RecycleBinSize
│   ├── Get-BrowserCachesSummary
│   └── Get-UsageBreakdown
├── Display Functions
│   ├── Show-PhysicalDisks
│   ├── Show-SMARTStatus
│   ├── Show-Volumes
│   ├── Show-TrimStatus
│   └── Show-UsageBreakdown
├── Cleanup Functions
│   └── Invoke-SafeDiskCleanup
├── Report Generation
│   ├── Export-HTMLReport
│   └── Export-TextReport
└── Main Execution
    ├── Show-MainMenu
    ├── Invoke-FullScan
    └── Start-InteractiveMode
```

## Development Guidelines

### Code Style

1. **Use Approved Verbs**: Get-, Set-, Test-, Invoke-, Export-, Show-, Start-
2. **CmdletBinding**: All functions should use `[CmdletBinding()]`
3. **Comment-Based Help**: Include `.SYNOPSIS` for all functions
4. **Error Handling**: Use try/catch with `-ErrorAction SilentlyContinue` for graceful degradation
5. **Verbose Output**: Use `Write-Verbose` for debug information

### Naming Conventions

- Functions: PascalCase with Verb-Noun format
- Variables: camelCase for local, PascalCase for parameters
- Script-scope variables: `$Script:VariableName`

### Example Function Template

```powershell
function Get-ExampleData {
    <#
    .SYNOPSIS
        Brief description of what this function does
    .PARAMETER ParameterName
        Description of the parameter
    .EXAMPLE
        Get-ExampleData -ParameterName "value"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ParameterName
    )

    try {
        # Implementation
    }
    catch {
        Write-Verbose "Error in Get-ExampleData: $_"
        return $null
    }
}
```

## Safety Requirements

### MUST NEVER Do

- Modify the Windows Registry
- Install drivers or kernel-level components
- Create background services or scheduled tasks
- Delete files without explicit user confirmation
- Send data over the network (telemetry, analytics)
- Modify system files or protected directories
- Bypass UAC or request unnecessary permissions
- Store user data persistently

### MUST Always Do

- Display clear information about what will happen before any action
- Require explicit user confirmation for any destructive operation
- Provide graceful degradation when features aren't available
- Work without administrator privileges (with reduced functionality)
- Use only native Windows APIs and built-in tools

## Windows APIs Used

### Storage Cmdlets (Preferred)

```powershell
Get-PhysicalDisk              # Physical disk info, SMART status
Get-StorageReliabilityCounter # Reliability data (temperature, errors, wear)
Get-Volume                    # Volume information
```

### WMI/CIM Classes (Fallback)

```powershell
Win32_DiskDrive               # Physical disk info
Win32_LogicalDisk             # Partition/volume info
Win32_OperatingSystem         # System info
```

### External Commands

```powershell
fsutil behavior query DisableDeleteNotify  # TRIM status
cleanmgr.exe /D <drive>                    # Windows Disk Cleanup
```

## Safe Cleanup Categories

Only these categories are considered safe for automated pre-selection:

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

### Explicitly Excluded (Too Aggressive)

- System Restore Points
- Previous Windows Installations
- Device Driver Packages
- Windows Defender files
- Debug dump files (may be needed for diagnostics)

## Testing Requirements

### Test Environments

- [ ] Windows 10 21H2
- [ ] Windows 10 22H2
- [ ] Windows 11 22H2
- [ ] Windows 11 23H2

### Test Scenarios

1. **Without Admin Privileges**
   - Tool should run with reduced functionality
   - Clear message about limited features
   - No errors or crashes

2. **With Admin Privileges**
   - Full SMART data available
   - Temperature readings (if supported)
   - All reliability counters

3. **Disk Configurations**
   - Single HDD
   - Single SSD (SATA)
   - Single NVMe SSD
   - Multiple drives (mixed types)
   - RAID configurations (basic detection)

4. **Edge Cases**
   - Very low disk space (< 1GB free)
   - Drives with no volume label
   - Disconnected/offline drives
   - Encrypted drives (BitLocker)

### Test Commands

```powershell
# Interactive mode
.\JAB-DriveHygieneCheck.ps1

# Quick scan
.\JAB-DriveHygieneCheck.ps1 -QuickScan

# Export HTML report
.\JAB-DriveHygieneCheck.ps1 -ExportReport -ReportFormat HTML

# Export text report
.\JAB-DriveHygieneCheck.ps1 -ExportReport -ReportFormat Text

# With verbose output
.\JAB-DriveHygieneCheck.ps1 -QuickScan -Verbose
```

## Distribution

### File Preparation

1. Script is distributed as a single `.ps1` file
2. No compilation required
3. Users can inspect before running

### Code Signing (Optional)

For enterprise distribution, consider signing the script:

```powershell
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert
Set-AuthenticodeSignature -FilePath .\JAB-DriveHygieneCheck.ps1 -Certificate $cert
```

## Versioning

Version format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes or significant feature additions
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, minor improvements

Update version in script header:
```powershell
$Script:Version = "1.0.0"
```

## Changelog

### v1.0.0 (Initial Release)
- Physical disk enumeration and health status
- SMART data retrieval (with admin)
- Volume space analysis
- TRIM status detection
- Usage breakdown by category
- Browser cache detection
- Safe disk cleanup invocation
- HTML and text report export
- Interactive menu system

## Support

- Website: https://jabsystems.io
- Email: info@jabsystems.io
