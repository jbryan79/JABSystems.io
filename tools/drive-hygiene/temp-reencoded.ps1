<#
.SYNOPSIS
    JAB Drive Hygiene Check - Safe, read-only disk inspection and cleanup utility

.DESCRIPTION
    A Windows disk inspection utility that analyzes drive health, SMART status,
    SSD optimization, and disk usage. Identifies cleanup candidates and optionally
    invokes native Windows Disk Cleanup with pre-vetted safe categories.

    This tool is read-only by default and makes no changes without explicit
    user confirmation.

.PARAMETER QuickScan
    Run a quick scan without interactive prompts

.PARAMETER ExportReport
    Export results to a report file

.PARAMETER OutputPath
    Path for exported report (default: current directory)

.PARAMETER ReportFormat
    Format for exported report: HTML or Text (default: HTML)

.EXAMPLE
    .\JAB-DriveHygieneCheck.ps1
    Run interactive mode with full menu

.EXAMPLE
    .\JAB-DriveHygieneCheck.ps1 -QuickScan
    Run quick scan without prompts

.EXAMPLE
    .\JAB-DriveHygieneCheck.ps1 -ExportReport -OutputPath "C:\Reports" -ReportFormat HTML
    Export HTML report to specified path

.NOTES
    Author: JAB Systems
    Website: https://jabsystems.io
    Version: 1.0.0
    License: MIT

    SAFETY GUARANTEES:
    - Read-only by default
    - No registry modifications
    - No driver installations
    - No automatic deletions
    - No telemetry or data collection
#>

[CmdletBinding()]
param(
    [switch]$QuickScan,
    [switch]$ExportReport,
    [string]$OutputPath = (Get-Location).Path,
    [ValidateSet('HTML', 'Text')]
    [string]$ReportFormat = 'HTML'
)

#Requires -Version 5.1

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:Version = "1.0.0"
$Script:ProductName = "JAB Drive Hygiene Check"

# Safe cleanup categories for Windows Disk Cleanup
# These are pre-vetted and will not cause system issues
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

# Categories explicitly NOT included (too aggressive)
# - System Restore Points
# - Previous Windows Installations
# - Device Driver Packages
# - Windows Defender files

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Header {
    <#
    .SYNOPSIS
        Displays the application header/banner
    #>
    Clear-Host
    $banner = @"

     Ã¢â€¢"Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢-
     Ã¢â€¢'                                                               Ã¢â€¢'
     Ã¢â€¢'        Ã¢-'Ã¢-Ë†Ã¢-â‚¬Ã¢-Ë†Ã¢-'Ã¢-Ë†Ã¢-â‚¬Ã¢-Ë†Ã¢-'Ã¢-Ë†Ã¢-â‚¬Ã¢-â€žÃ¢-'Ã¢-'Ã¢-'Ã¢-Ë†Ã¢-â‚¬Ã¢-â€žÃ¢-'Ã¢-Ë†Ã¢-â‚¬Ã¢-â€žÃ¢-'Ã¢-â‚¬Ã¢-Ë†Ã¢-â‚¬Ã¢-'Ã¢-Ë†Ã¢-'Ã¢-Ë†Ã¢-'Ã¢-Ë†Ã¢-â‚¬Ã¢-â‚¬                     Ã¢â€¢'
     Ã¢â€¢'        Ã¢-'Ã¢-Ë†Ã¢-'Ã¢-Ë†Ã¢-'Ã¢-Ë†Ã¢-â‚¬Ã¢-Ë†Ã¢-'Ã¢-Ë†Ã¢-â‚¬Ã¢-â€žÃ¢-'Ã¢-'Ã¢-'Ã¢-Ë†Ã¢-'Ã¢-Ë†Ã¢-'Ã¢-Ë†Ã¢-â‚¬Ã¢-â€žÃ¢-'Ã¢-'Ã¢-Ë†Ã¢-'Ã¢-'Ã¢-â‚¬Ã¢-â€žÃ¢-â‚¬Ã¢-'Ã¢-Ë†Ã¢-â‚¬Ã¢-â‚¬                     Ã¢â€¢'
     Ã¢â€¢'        Ã¢-'Ã¢-â‚¬Ã¢-â‚¬Ã¢-â‚¬Ã¢-'Ã¢-â‚¬Ã¢-'Ã¢-â‚¬Ã¢-'Ã¢-â‚¬Ã¢-â‚¬Ã¢-'Ã¢-'Ã¢-'Ã¢-'Ã¢-â‚¬Ã¢-â‚¬Ã¢-'Ã¢-'Ã¢-â‚¬Ã¢-'Ã¢-â‚¬Ã¢-'Ã¢-â‚¬Ã¢-â‚¬Ã¢-â‚¬Ã¢-'Ã¢-'Ã¢-â‚¬Ã¢-'Ã¢-'Ã¢-â‚¬Ã¢-â‚¬Ã¢-â‚¬                     Ã¢â€¢'
     Ã¢â€¢'                                                               Ã¢â€¢'
     Ã¢â€¢'              H Y G I E N E   C H E C K                        Ã¢â€¢'
     Ã¢â€¢'                                                               Ã¢â€¢'
     Ã¢â€¢'          Safe, read-only disk inspection utility              Ã¢â€¢'
     Ã¢â€¢'                                                               Ã¢â€¢'
     Ã¢â€¢Å¡Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

"@
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "     Version $Script:Version | https://jabsystems.io" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-SectionHeader {
    <#
    .SYNOPSIS
        Displays a section header with consistent formatting
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ""
    Write-Host "  Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â" -ForegroundColor DarkCyan
    Write-Host "   $Title" -ForegroundColor White
    Write-Host "  Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-SubHeader {
    <#
    .SYNOPSIS
        Displays a sub-section header
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ""
    Write-Host "   Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬ $Title Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬" -ForegroundColor Gray
    Write-Host ""
}

function Format-ByteSize {
    <#
    .SYNOPSIS
        Converts bytes to human-readable format (KB, MB, GB, TB)
    #>
    param(
        [Parameter(Mandatory)]
        [long]$Bytes
    )

    if ($Bytes -ge 1TB) {
        return "{0:N2} TB" -f ($Bytes / 1TB)
    }
    elseif ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }
    elseif ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }
    elseif ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    }
    else {
        return "$Bytes Bytes"
    }
}

function Write-StatusLine {
    <#
    .SYNOPSIS
        Writes a status line with label and value
    #>
    param(
        [string]$Label,
        [string]$Value,
        [string]$Status = "Info",
        [int]$Indent = 4
    )

    $padding = " " * $Indent
    $labelPadded = $Label.PadRight(25)

    $statusColor = switch ($Status) {
        "Good"    { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        "Info"    { "White" }
        default   { "Gray" }
    }

    Write-Host "$padding$labelPadded" -NoNewline -ForegroundColor Gray
    Write-Host $Value -ForegroundColor $statusColor
}

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
        Tests if the script is running with administrator privileges
    #>
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================================
# DISK INSPECTION FUNCTIONS
# ============================================================================

function Get-PhysicalDiskInfo {
    <#
    .SYNOPSIS
        Retrieves information about all physical disks
    #>
    [CmdletBinding()]
    param()

    $disks = @()

    try {
        # Get physical disk information using Storage cmdlets
        $physicalDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue

        foreach ($disk in $physicalDisks) {
            $diskInfo = [PSCustomObject]@{
                DeviceId          = $disk.DeviceId
                FriendlyName      = $disk.FriendlyName
                MediaType         = $disk.MediaType
                BusType           = $disk.BusType
                HealthStatus      = $disk.HealthStatus
                OperationalStatus = $disk.OperationalStatus
                Size              = $disk.Size
                SizeFormatted     = Format-ByteSize -Bytes $disk.Size
            }
            $disks += $diskInfo
        }
    }
    catch {
        Write-Verbose "Get-PhysicalDisk not available, falling back to WMI"
    }

    # Fallback to WMI if Storage cmdlets not available
    if ($disks.Count -eq 0) {
        try {
            $wmiDisks = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction SilentlyContinue

            foreach ($disk in $wmiDisks) {
                $diskInfo = [PSCustomObject]@{
                    DeviceId          = $disk.Index
                    FriendlyName      = $disk.Model
                    MediaType         = if ($disk.MediaType -match "SSD|Solid") { "SSD" } else { "HDD" }
                    BusType           = $disk.InterfaceType
                    HealthStatus      = "Unknown"
                    OperationalStatus = $disk.Status
                    Size              = $disk.Size
                    SizeFormatted     = Format-ByteSize -Bytes $disk.Size
                }
                $disks += $diskInfo
            }
        }
        catch {
            Write-Warning "Unable to retrieve disk information: $_"
        }
    }

    return $disks
}

function Get-SMARTStatus {
    <#
    .SYNOPSIS
        Retrieves SMART health status for physical disks
    #>
    [CmdletBinding()]
    param()

    $smartData = @()

    try {
        $physicalDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue

        foreach ($disk in $physicalDisks) {
            $reliability = $null

            # Try to get reliability counters (requires admin)
            try {
                $reliability = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
            }
            catch {
                # Silently continue if not available
            }

            $smartInfo = [PSCustomObject]@{
                DiskId            = $disk.DeviceId
                FriendlyName      = $disk.FriendlyName
                HealthStatus      = $disk.HealthStatus
                OperationalStatus = $disk.OperationalStatus
                Temperature       = if ($reliability) { "$($reliability.Temperature)Ã‚Â°C" } else { "N/A" }
                ReadErrors        = if ($reliability) { $reliability.ReadErrorsTotal } else { "N/A" }
                WriteErrors       = if ($reliability) { $reliability.WriteErrorsTotal } else { "N/A" }
                PowerOnHours      = if ($reliability) { $reliability.PowerOnHours } else { "N/A" }
                Wear              = if ($reliability -and $reliability.Wear) { "$($reliability.Wear)%" } else { "N/A" }
            }
            $smartData += $smartInfo
        }
    }
    catch {
        Write-Verbose "SMART data retrieval failed: $_"
    }

    return $smartData
}

function Get-LogicalDiskInfo {
    <#
    .SYNOPSIS
        Retrieves information about logical disks (volumes)
    #>
    [CmdletBinding()]
    param()

    $volumes = @()

    try {
        $logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue

        foreach ($disk in $logicalDisks) {
            $usedSpace = $disk.Size - $disk.FreeSpace
            $percentUsed = if ($disk.Size -gt 0) { [math]::Round(($usedSpace / $disk.Size) * 100, 1) } else { 0 }
            $percentFree = 100 - $percentUsed

            $volumeInfo = [PSCustomObject]@{
                DriveLetter     = $disk.DeviceID
                VolumeName      = if ($disk.VolumeName) { $disk.VolumeName } else { "(No Label)" }
                FileSystem      = $disk.FileSystem
                TotalSize       = $disk.Size
                TotalSizeFormatted = Format-ByteSize -Bytes $disk.Size
                FreeSpace       = $disk.FreeSpace
                FreeSpaceFormatted = Format-ByteSize -Bytes $disk.FreeSpace
                UsedSpace       = $usedSpace
                UsedSpaceFormatted = Format-ByteSize -Bytes $usedSpace
                PercentUsed     = $percentUsed
                PercentFree     = $percentFree
                Status          = if ($percentFree -lt 10) { "Critical" } elseif ($percentFree -lt 20) { "Warning" } else { "Healthy" }
            }
            $volumes += $volumeInfo
        }
    }
    catch {
        Write-Warning "Unable to retrieve volume information: $_"
    }

    return $volumes
}

# ============================================================================
# SSD-SPECIFIC FUNCTIONS
# ============================================================================

function Get-TrimStatus {
    <#
    .SYNOPSIS
        Checks if TRIM is enabled for SSDs
    #>
    [CmdletBinding()]
    param()

    $trimInfo = [PSCustomObject]@{
        TrimEnabled = $false
        RawOutput   = ""
        Details     = ""
    }

    try {
        $result = fsutil behavior query DisableDeleteNotify 2>&1
        $trimInfo.RawOutput = $result

        if ($result -match "DisableDeleteNotify\s*=\s*0" -or $result -match "NTFS DisableDeleteNotify\s*=\s*0") {
            $trimInfo.TrimEnabled = $true
            $trimInfo.Details = "TRIM is enabled (recommended for SSDs)"
        }
        elseif ($result -match "DisableDeleteNotify\s*=\s*1" -or $result -match "NTFS DisableDeleteNotify\s*=\s*1") {
            $trimInfo.TrimEnabled = $false
            $trimInfo.Details = "TRIM is disabled"
        }
        else {
            $trimInfo.Details = "Unable to determine TRIM status"
        }
    }
    catch {
        $trimInfo.Details = "Error checking TRIM status: $_"
    }

    return $trimInfo
}

function Get-OptimizationStatus {
    <#
    .SYNOPSIS
        Gets the optimization/defrag status for drives
    #>
    [CmdletBinding()]
    param()

    $optimizationStatus = @()

    try {
        $volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }

        foreach ($volume in $volumes) {
            $status = [PSCustomObject]@{
                DriveLetter         = "$($volume.DriveLetter):"
                FileSystem          = $volume.FileSystemType
                OptimizationNeeded  = "Unknown"
                LastOptimization    = "Unknown"
                MediaType           = "Unknown"
            }

            # Try to get optimization status using Optimize-Volume (dry run)
            try {
                $optInfo = Get-ScheduledTask -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue
                if ($optInfo) {
                    $status.LastOptimization = "Scheduled task exists"
                }
            }
            catch {
                # Silently continue
            }

            $optimizationStatus += $status
        }
    }
    catch {
        Write-Verbose "Optimization status check failed: $_"
    }

    return $optimizationStatus
}

# ============================================================================
# USAGE ANALYSIS FUNCTIONS
# ============================================================================

function Get-FolderSize {
    <#
    .SYNOPSIS
        Calculates the total size of a folder
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [switch]$IncludeHidden
    )

    $size = 0
    $fileCount = 0

    if (Test-Path $Path) {
        try {
            $items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                if (-not $item.PSIsContainer) {
                    $size += $item.Length
                    $fileCount++
                }
            }
        }
        catch {
            Write-Verbose "Error scanning $Path : $_"
        }
    }

    return [PSCustomObject]@{
        Path          = $Path
        Size          = $size
        SizeFormatted = Format-ByteSize -Bytes $size
        FileCount     = $fileCount
    }
}

function Get-TempFilesSummary {
    <#
    .SYNOPSIS
        Analyzes temporary file locations
    #>
    [CmdletBinding()]
    param()

    $tempLocations = @()

    # User temp folder
    $userTemp = Get-FolderSize -Path $env:TEMP
    $userTemp | Add-Member -NotePropertyName "Category" -NotePropertyValue "User Temp Files"
    $tempLocations += $userTemp

    # Windows temp folder
    $windowsTemp = Get-FolderSize -Path "$env:SystemRoot\Temp"
    $windowsTemp | Add-Member -NotePropertyName "Category" -NotePropertyValue "Windows Temp Files"
    $tempLocations += $windowsTemp

    # Prefetch
    $prefetch = Get-FolderSize -Path "$env:SystemRoot\Prefetch"
    $prefetch | Add-Member -NotePropertyName "Category" -NotePropertyValue "Prefetch Cache"
    $tempLocations += $prefetch

    return $tempLocations
}

function Get-SystemCachesSummary {
    <#
    .SYNOPSIS
        Analyzes system cache locations
    #>
    [CmdletBinding()]
    param()

    $caches = @()

    # Windows Update cache
    $wuCache = Get-FolderSize -Path "$env:SystemRoot\SoftwareDistribution\Download"
    $wuCache | Add-Member -NotePropertyName "Category" -NotePropertyValue "Windows Update Cache"
    $caches += $wuCache

    # Delivery Optimization
    $doCache = Get-FolderSize -Path "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"
    $doCache | Add-Member -NotePropertyName "Category" -NotePropertyValue "Delivery Optimization"
    $caches += $doCache

    # Windows Installer cache
    $installerCache = Get-FolderSize -Path "$env:SystemRoot\Installer\`$PatchCache`$"
    $installerCache | Add-Member -NotePropertyName "Category" -NotePropertyValue "Installer Patch Cache"
    $caches += $installerCache

    return $caches
}

function Get-RecycleBinSize {
    <#
    .SYNOPSIS
        Gets the size of the Recycle Bin for each drive
    #>
    [CmdletBinding()]
    param()

    $recycleBinInfo = @()

    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.NameSpace(0x0a) # Recycle Bin

        $totalSize = 0
        $itemCount = 0

        if ($recycleBin) {
            foreach ($item in $recycleBin.Items()) {
                $totalSize += $item.Size
                $itemCount++
            }
        }

        $recycleBinInfo += [PSCustomObject]@{
            Category      = "Recycle Bin (All Drives)"
            Path          = "Recycle Bin"
            Size          = $totalSize
            SizeFormatted = Format-ByteSize -Bytes $totalSize
            FileCount     = $itemCount
        }
    }
    catch {
        Write-Verbose "Error getting Recycle Bin size: $_"
    }

    return $recycleBinInfo
}

function Get-BrowserCachesSummary {
    <#
    .SYNOPSIS
        Analyzes browser cache locations
    #>
    [CmdletBinding()]
    param()

    $browserCaches = @()

    # Chrome
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    if (Test-Path $chromePath) {
        $chromeCache = Get-FolderSize -Path $chromePath
        $chromeCache | Add-Member -NotePropertyName "Category" -NotePropertyValue "Google Chrome Cache"
        $browserCaches += $chromeCache
    }

    # Edge
    $edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    if (Test-Path $edgePath) {
        $edgeCache = Get-FolderSize -Path $edgePath
        $edgeCache | Add-Member -NotePropertyName "Category" -NotePropertyValue "Microsoft Edge Cache"
        $browserCaches += $edgeCache
    }

    # Firefox
    $firefoxProfile = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $firefoxProfile) {
        $firefoxCache = Get-FolderSize -Path $firefoxProfile
        $firefoxCache | Add-Member -NotePropertyName "Category" -NotePropertyValue "Mozilla Firefox Cache"
        $browserCaches += $firefoxCache
    }

    return $browserCaches
}

function Get-UsageBreakdown {
    <#
    .SYNOPSIS
        Gets a complete breakdown of disk usage by category
    #>
    [CmdletBinding()]
    param()

    Write-Host "    Analyzing disk usage (this may take a moment)..." -ForegroundColor Yellow

    $breakdown = @()

    # Temp files
    $tempFiles = Get-TempFilesSummary
    $breakdown += $tempFiles

    # System caches
    $systemCaches = Get-SystemCachesSummary
    $breakdown += $systemCaches

    # Recycle Bin
    $recycleBin = Get-RecycleBinSize
    $breakdown += $recycleBin

    # Browser caches
    $browserCaches = Get-BrowserCachesSummary
    $breakdown += $browserCaches

    return $breakdown | Sort-Object -Property Size -Descending
}

# ============================================================================
# DISPLAY FUNCTIONS
# ============================================================================

function Show-PhysicalDisks {
    <#
    .SYNOPSIS
        Displays physical disk information
    #>
    param(
        [array]$Disks
    )

    Write-SectionHeader "Physical Disks"

    if ($Disks.Count -eq 0) {
        Write-Host "    No physical disk information available." -ForegroundColor Yellow
        return
    }

    foreach ($disk in $Disks) {
        $healthColor = switch ($disk.HealthStatus) {
            "Healthy" { "Green" }
            "Warning" { "Yellow" }
            "Unhealthy" { "Red" }
            default { "White" }
        }

        Write-Host "    Ã¢"Å'Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬" -ForegroundColor DarkGray
        Write-Host "    Ã¢"â€š " -NoNewline -ForegroundColor DarkGray
        Write-Host "Disk $($disk.DeviceId): $($disk.FriendlyName)" -ForegroundColor White
        Write-Host "    Ã¢"Å"Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬" -ForegroundColor DarkGray
        Write-StatusLine -Label "Type" -Value $disk.MediaType -Indent 6
        Write-StatusLine -Label "Bus" -Value $disk.BusType -Indent 6
        Write-StatusLine -Label "Size" -Value $disk.SizeFormatted -Indent 6
        Write-StatusLine -Label "Health" -Value $disk.HealthStatus -Status $(if ($disk.HealthStatus -eq "Healthy") { "Good" } else { "Warning" }) -Indent 6
        Write-StatusLine -Label "Status" -Value $disk.OperationalStatus -Indent 6
        Write-Host "    Ã¢""Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬" -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Show-SMARTStatus {
    <#
    .SYNOPSIS
        Displays SMART status information
    #>
    param(
        [array]$SmartData
    )

    Write-SubHeader "SMART Status"

    if ($SmartData.Count -eq 0) {
        Write-Host "    SMART data not available. Run as Administrator for full details." -ForegroundColor Yellow
        return
    }

    foreach ($smart in $SmartData) {
        Write-Host "    Disk $($smart.DiskId): $($smart.FriendlyName)" -ForegroundColor Cyan

        $healthStatus = switch ($smart.HealthStatus) {
            "Healthy" { "Good" }
            "Warning" { "Warning" }
            "Unhealthy" { "Error" }
            default { "Info" }
        }

        Write-StatusLine -Label "Health" -Value $smart.HealthStatus -Status $healthStatus -Indent 6
        Write-StatusLine -Label "Temperature" -Value $smart.Temperature -Indent 6
        Write-StatusLine -Label "Power-On Hours" -Value $smart.PowerOnHours -Indent 6
        Write-StatusLine -Label "Read Errors" -Value $smart.ReadErrors -Indent 6
        Write-StatusLine -Label "Write Errors" -Value $smart.WriteErrors -Indent 6

        if ($smart.Wear -ne "N/A") {
            Write-StatusLine -Label "SSD Wear Level" -Value $smart.Wear -Indent 6
        }

        Write-Host ""
    }
}

function Show-Volumes {
    <#
    .SYNOPSIS
        Displays volume/partition information
    #>
    param(
        [array]$Volumes
    )

    Write-SectionHeader "Volumes"

    foreach ($vol in $Volumes) {
        $barLength = 40
        $usedBars = [math]::Round(($vol.PercentUsed / 100) * $barLength)
        $freeBars = $barLength - $usedBars

        $barColor = switch ($vol.Status) {
            "Critical" { "Red" }
            "Warning" { "Yellow" }
            default { "Green" }
        }

        Write-Host "    $($vol.DriveLetter) $($vol.VolumeName)" -ForegroundColor White
        Write-Host "    [" -NoNewline -ForegroundColor Gray
        Write-Host ("Ã¢-Ë†" * $usedBars) -NoNewline -ForegroundColor $barColor
        Write-Host ("Ã¢-'" * $freeBars) -NoNewline -ForegroundColor DarkGray
        Write-Host "] $($vol.PercentUsed)% used" -ForegroundColor Gray
        Write-Host "    Used: $($vol.UsedSpaceFormatted) / Total: $($vol.TotalSizeFormatted) / Free: $($vol.FreeSpaceFormatted)" -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Show-TrimStatus {
    <#
    .SYNOPSIS
        Displays TRIM status
    #>
    param(
        [PSCustomObject]$TrimInfo
    )

    Write-SubHeader "SSD TRIM Status"

    $status = if ($TrimInfo.TrimEnabled) { "Good" } else { "Warning" }
    $value = if ($TrimInfo.TrimEnabled) { "Enabled" } else { "Disabled" }

    Write-StatusLine -Label "TRIM" -Value $value -Status $status
    Write-Host "    $($TrimInfo.Details)" -ForegroundColor DarkGray
}

function Show-UsageBreakdown {
    <#
    .SYNOPSIS
        Displays disk usage breakdown by category
    #>
    param(
        [array]$Breakdown
    )

    Write-SectionHeader "Cleanup Candidates"

    $totalReclaimable = ($Breakdown | Measure-Object -Property Size -Sum).Sum

    Write-Host "    Total potentially reclaimable: " -NoNewline -ForegroundColor Gray
    Write-Host (Format-ByteSize -Bytes $totalReclaimable) -ForegroundColor Yellow
    Write-Host ""

    foreach ($item in $Breakdown) {
        if ($item.Size -gt 0) {
            Write-Host "    Ã¢"Å"Ã¢"â‚¬ " -NoNewline -ForegroundColor DarkGray
            Write-Host "$($item.Category)".PadRight(35) -NoNewline -ForegroundColor Gray
            Write-Host $item.SizeFormatted -ForegroundColor $(if ($item.Size -gt 500MB) { "Yellow" } elseif ($item.Size -gt 100MB) { "White" } else { "DarkGray" })
            Write-Host "    Ã¢"â€š  $($item.FileCount) files in $($item.Path)" -ForegroundColor DarkGray
        }
    }
}

# ============================================================================
# CLEANUP FUNCTIONS
# ============================================================================

function Invoke-SafeDiskCleanup {
    <#
    .SYNOPSIS
        Launches Windows Disk Cleanup with safe, pre-vetted categories
    #>
    [CmdletBinding()]
    param(
        [string]$DriveLetter = "C"
    )

    Write-SectionHeader "Safe Disk Cleanup"

    Write-Host "    This will launch the native Windows Disk Cleanup utility." -ForegroundColor Cyan
    Write-Host "    The following safe categories are recommended:" -ForegroundColor Gray
    Write-Host ""

    foreach ($category in $Script:SafeCleanupCategories) {
        Write-Host "      Ã¢â‚¬Â¢ $category" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "    " -NoNewline
    Write-Host "NOTE: " -NoNewline -ForegroundColor Yellow
    Write-Host "You will make the final selections in the Disk Cleanup window." -ForegroundColor Gray
    Write-Host "    No files will be deleted without your explicit confirmation." -ForegroundColor Gray
    Write-Host ""

    $confirm = Read-Host "    Launch Disk Cleanup for drive $($DriveLetter):? (Y/N)"

    if ($confirm -eq 'Y' -or $confirm -eq 'y') {
        Write-Host ""
        Write-Host "    Launching Windows Disk Cleanup..." -ForegroundColor Cyan

        try {
            Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/D $DriveLetter" -Wait:$false
            Write-Host "    Disk Cleanup launched successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "    Error launching Disk Cleanup: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "    Disk Cleanup cancelled." -ForegroundColor Yellow
    }
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

function Export-HTMLReport {
    <#
    .SYNOPSIS
        Exports scan results to an HTML report
    #>
    [CmdletBinding()]
    param(
        [array]$PhysicalDisks,
        [array]$SmartData,
        [array]$Volumes,
        [PSCustomObject]$TrimInfo,
        [array]$UsageBreakdown,
        [string]$OutputPath
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $filename = "DriveHygieneCheck_$timestamp.html"
    $filepath = Join-Path $OutputPath $filename

    $totalReclaimable = ($UsageBreakdown | Measure-Object -Property Size -Sum).Sum

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>JAB Drive Hygiene Check Report</title>
    <style>
        body { font-family: system-ui, -apple-system, sans-serif; background: #0b0f14; color: #f5f7fa; padding: 2rem; line-height: 1.6; }
        .container { max-width: 900px; margin: 0 auto; }
        h1 { color: #3aa0ff; border-bottom: 2px solid #3aa0ff; padding-bottom: 0.5rem; }
        h2 { color: #9aa7b8; margin-top: 2rem; }
        .card { background: #111822; border-radius: 8px; padding: 1.5rem; margin: 1rem 0; border: 1px solid rgba(255,255,255,0.05); }
        .status-good { color: #22c55e; }
        .status-warning { color: #fbbf24; }
        .status-error { color: #ef4444; }
        table { width: 100%; border-collapse: collapse; margin: 1rem 0; }
        th, td { padding: 0.75rem; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.05); }
        th { color: #9aa7b8; font-weight: 500; }
        .bar { background: #1e293b; border-radius: 4px; height: 20px; overflow: hidden; }
        .bar-fill { height: 100%; background: #3aa0ff; }
        .highlight { color: #fbbf24; font-size: 1.5rem; font-weight: 600; }
        .footer { margin-top: 3rem; padding-top: 1rem; border-top: 1px solid rgba(255,255,255,0.05); color: #9aa7b8; font-size: 0.85rem; text-align: center; }
        a { color: #3aa0ff; }
    </style>
</head>
<body>
    <div class="container">
        <h1>JAB Drive Hygiene Check Report</h1>
        <p>Generated: $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm:ss")</p>

        <h2>Physical Disks</h2>
        <div class="card">
            <table>
                <tr><th>Disk</th><th>Type</th><th>Size</th><th>Health</th></tr>
                $(foreach ($disk in $PhysicalDisks) {
                    $healthClass = switch ($disk.HealthStatus) { "Healthy" { "status-good" } "Warning" { "status-warning" } default { "status-error" } }
                    "<tr><td>$($disk.FriendlyName)</td><td>$($disk.MediaType)</td><td>$($disk.SizeFormatted)</td><td class='$healthClass'>$($disk.HealthStatus)</td></tr>"
                })
            </table>
        </div>

        <h2>Volumes</h2>
        <div class="card">
            $(foreach ($vol in $Volumes) {
                $barColor = switch ($vol.Status) { "Critical" { "#ef4444" } "Warning" { "#fbbf24" } default { "#22c55e" } }
                @"
                <div style="margin-bottom: 1.5rem;">
                    <strong>$($vol.DriveLetter) $($vol.VolumeName)</strong> - $($vol.FileSystem)
                    <div class="bar"><div class="bar-fill" style="width: $($vol.PercentUsed)%; background: $barColor;"></div></div>
                    <small>$($vol.UsedSpaceFormatted) used of $($vol.TotalSizeFormatted) ($($vol.PercentFree)% free)</small>
                </div>
"@
            })
        </div>

        <h2>SSD Status</h2>
        <div class="card">
            <p>TRIM: <span class="$(if ($TrimInfo.TrimEnabled) { 'status-good' } else { 'status-warning' })">$(if ($TrimInfo.TrimEnabled) { 'Enabled' } else { 'Disabled' })</span></p>
            <p>$($TrimInfo.Details)</p>
        </div>

        <h2>Cleanup Candidates</h2>
        <div class="card">
            <p>Total potentially reclaimable: <span class="highlight">$(Format-ByteSize -Bytes $totalReclaimable)</span></p>
            <table>
                <tr><th>Category</th><th>Size</th><th>Files</th></tr>
                $(foreach ($item in $UsageBreakdown | Where-Object { $_.Size -gt 0 }) {
                    "<tr><td>$($item.Category)</td><td>$($item.SizeFormatted)</td><td>$($item.FileCount)</td></tr>"
                })
            </table>
        </div>

        <div class="footer">
            <p>Generated by <strong>JAB Drive Hygiene Check</strong> v$Script:Version</p>
            <p><a href="https://jabsystems.io">jabsystems.io</a></p>
        </div>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $filepath -Encoding UTF8

    return $filepath
}

function Export-TextReport {
    <#
    .SYNOPSIS
        Exports scan results to a text report
    #>
    [CmdletBinding()]
    param(
        [array]$PhysicalDisks,
        [array]$SmartData,
        [array]$Volumes,
        [PSCustomObject]$TrimInfo,
        [array]$UsageBreakdown,
        [string]$OutputPath
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $filename = "DriveHygieneCheck_$timestamp.txt"
    $filepath = Join-Path $OutputPath $filename

    $totalReclaimable = ($UsageBreakdown | Measure-Object -Property Size -Sum).Sum

    $report = @"
================================================================================
                        JAB DRIVE HYGIENE CHECK REPORT
================================================================================
Generated: $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm:ss")
Version: $Script:Version

--------------------------------------------------------------------------------
                              PHYSICAL DISKS
--------------------------------------------------------------------------------
$(foreach ($disk in $PhysicalDisks) {
"
Disk: $($disk.FriendlyName)
  Type:   $($disk.MediaType)
  Bus:    $($disk.BusType)
  Size:   $($disk.SizeFormatted)
  Health: $($disk.HealthStatus)
  Status: $($disk.OperationalStatus)
"
})

--------------------------------------------------------------------------------
                                VOLUMES
--------------------------------------------------------------------------------
$(foreach ($vol in $Volumes) {
"
$($vol.DriveLetter) $($vol.VolumeName) ($($vol.FileSystem))
  Total:  $($vol.TotalSizeFormatted)
  Used:   $($vol.UsedSpaceFormatted) ($($vol.PercentUsed)%)
  Free:   $($vol.FreeSpaceFormatted) ($($vol.PercentFree)%)
  Status: $($vol.Status)
"
})

--------------------------------------------------------------------------------
                              SSD STATUS
--------------------------------------------------------------------------------
TRIM: $(if ($TrimInfo.TrimEnabled) { 'Enabled' } else { 'Disabled' })
$($TrimInfo.Details)

--------------------------------------------------------------------------------
                          CLEANUP CANDIDATES
--------------------------------------------------------------------------------
Total Potentially Reclaimable: $(Format-ByteSize -Bytes $totalReclaimable)

$(foreach ($item in $UsageBreakdown | Where-Object { $_.Size -gt 0 }) {
"$($item.Category.PadRight(40)) $($item.SizeFormatted.PadLeft(12)) ($($item.FileCount) files)"
})

================================================================================
                              END OF REPORT
================================================================================
Generated by JAB Drive Hygiene Check | https://jabsystems.io
"@

    $report | Out-File -FilePath $filepath -Encoding UTF8

    return $filepath
}

# ============================================================================
# MAIN MENU AND EXECUTION
# ============================================================================

function Show-MainMenu {
    <#
    .SYNOPSIS
        Displays the interactive main menu
    #>

    Write-Host ""
    Write-Host "  Ã¢â€¢"Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢-" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'                        MAIN MENU                              Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢Â Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â£" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'                                                               Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'   [1]  View Physical Disk Information                         Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'   [2]  View Volume Status                                     Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'   [3]  View SSD/TRIM Status                                   Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'   [4]  Analyze Cleanup Candidates                             Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'   [5]  Run Full Scan                                          Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'   [6]  Launch Safe Disk Cleanup                               Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'   [7]  Export Report                                          Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'                                                               Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'   [Q]  Quit                                                   Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢'                                                               Ã¢â€¢'" -ForegroundColor Cyan
    Write-Host "  Ã¢â€¢Å¡Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â" -ForegroundColor Cyan
    Write-Host ""

    $choice = Read-Host "  Select an option"
    return $choice
}

function Invoke-FullScan {
    <#
    .SYNOPSIS
        Runs a complete disk scan
    #>
    [CmdletBinding()]
    param(
        [switch]$Silent
    )

    if (-not $Silent) {
        Write-SectionHeader "Running Full Scan"
    }

    # Collect all data
    $physicalDisks = Get-PhysicalDiskInfo
    $smartData = Get-SMARTStatus
    $volumes = Get-LogicalDiskInfo
    $trimInfo = Get-TrimStatus
    $usageBreakdown = Get-UsageBreakdown

    if (-not $Silent) {
        # Display results
        Show-PhysicalDisks -Disks $physicalDisks
        Show-SMARTStatus -SmartData $smartData
        Show-Volumes -Volumes $volumes
        Show-TrimStatus -TrimInfo $trimInfo
        Show-UsageBreakdown -Breakdown $usageBreakdown
    }

    return @{
        PhysicalDisks   = $physicalDisks
        SmartData       = $smartData
        Volumes         = $volumes
        TrimInfo        = $trimInfo
        UsageBreakdown  = $usageBreakdown
    }
}

function Start-InteractiveMode {
    <#
    .SYNOPSIS
        Starts the interactive menu loop
    #>

    Write-Header

    # Check for admin privileges
    $isAdmin = Test-AdminPrivileges
    if (-not $isAdmin) {
        Write-Host "    " -NoNewline
        Write-Host "NOTE: " -NoNewline -ForegroundColor Yellow
        Write-Host "Running without administrator privileges." -ForegroundColor Gray
        Write-Host "    Some features (SMART data, reliability counters) may be limited." -ForegroundColor DarkGray
        Write-Host "    Right-click and 'Run as Administrator' for full functionality." -ForegroundColor DarkGray
        Write-Host ""
    }

    $scanResults = $null

    do {
        $choice = Show-MainMenu

        switch ($choice) {
            '1' {
                $physicalDisks = Get-PhysicalDiskInfo
                Show-PhysicalDisks -Disks $physicalDisks
                $smartData = Get-SMARTStatus
                Show-SMARTStatus -SmartData $smartData
                Read-Host "  Press Enter to continue"
            }
            '2' {
                $volumes = Get-LogicalDiskInfo
                Show-Volumes -Volumes $volumes
                Read-Host "  Press Enter to continue"
            }
            '3' {
                $trimInfo = Get-TrimStatus
                Show-TrimStatus -TrimInfo $trimInfo
                $optStatus = Get-OptimizationStatus
                Read-Host "  Press Enter to continue"
            }
            '4' {
                $usageBreakdown = Get-UsageBreakdown
                Show-UsageBreakdown -Breakdown $usageBreakdown
                Read-Host "  Press Enter to continue"
            }
            '5' {
                $scanResults = Invoke-FullScan
                Read-Host "  Press Enter to continue"
            }
            '6' {
                Invoke-SafeDiskCleanup
                Read-Host "  Press Enter to continue"
            }
            '7' {
                if ($null -eq $scanResults) {
                    Write-Host "    Running full scan first..." -ForegroundColor Yellow
                    $scanResults = Invoke-FullScan -Silent
                }

                Write-Host ""
                Write-Host "    Export format:" -ForegroundColor Cyan
                Write-Host "    [1] HTML Report (recommended)" -ForegroundColor White
                Write-Host "    [2] Text Report" -ForegroundColor White
                $formatChoice = Read-Host "    Select format"

                $format = if ($formatChoice -eq '2') { 'Text' } else { 'HTML' }

                $exportPath = if ($format -eq 'HTML') {
                    Export-HTMLReport @scanResults -OutputPath (Get-Location).Path
                }
                else {
                    Export-TextReport @scanResults -OutputPath (Get-Location).Path
                }

                Write-Host ""
                Write-Host "    Report saved to: $exportPath" -ForegroundColor Green
                Read-Host "  Press Enter to continue"
            }
            'Q' { }
            'q' { }
            default {
                Write-Host "    Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }

        if ($choice -notin @('Q', 'q')) {
            Write-Header
        }

    } while ($choice -notin @('Q', 'q'))

    Write-Host ""
    Write-Host "    Thank you for using JAB Drive Hygiene Check!" -ForegroundColor Cyan
    Write-Host "    Visit https://jabsystems.io for more tools." -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# ENTRY POINT
# ============================================================================

if ($QuickScan) {
    Write-Header
    $results = Invoke-FullScan

    if ($ExportReport) {
        $exportPath = if ($ReportFormat -eq 'HTML') {
            Export-HTMLReport @results -OutputPath $OutputPath
        }
        else {
            Export-TextReport @results -OutputPath $OutputPath
        }
        Write-Host ""
        Write-Host "    Report saved to: $exportPath" -ForegroundColor Green
    }
}
elseif ($ExportReport) {
    Write-Header
    Write-Host "    Running scan for export..." -ForegroundColor Yellow
    $results = Invoke-FullScan -Silent

    $exportPath = if ($ReportFormat -eq 'HTML') {
        Export-HTMLReport @results -OutputPath $OutputPath
    }
    else {
        Export-TextReport @results -OutputPath $OutputPath
    }
    Write-Host ""
    Write-Host "    Report saved to: $exportPath" -ForegroundColor Green
}
else {
    Start-InteractiveMode
}

