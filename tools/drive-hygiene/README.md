# JAB Drive Hygiene Check

A safe, read-only disk inspection and cleanup utility for Windows.

**No registry edits. No drivers. No surprises.**

---

## Quick Start

### Option 1: Double-Click the Launcher (Easiest)

1. Download the tool package
2. **Double-click `JAB-DriveHygieneCheck.bat`**
3. If prompted, allow administrator access (recommended for full features)

That's it. The tool launches automatically.

### Option 2: Run the Executable

1. Download `JAB-DriveHygieneCheck.exe`
2. **Double-click to run**
3. Allow administrator access when prompted

### Option 3: Run the PowerShell Script

1. Download `JAB-DriveHygieneCheck.ps1`
2. Right-click and select **"Run with PowerShell"**
3. If blocked, see [Troubleshooting](#troubleshooting) below

---

## What This Tool Does

- **Disk Health Inspection** - Checks SMART status across all connected drives
- **SSD Status** - Reports TRIM and optimization status for solid-state drives
- **Usage Analysis** - Shows what is consuming disk space by category
- **Cleanup Candidates** - Identifies safe-to-remove temporary files and caches
- **Safe Cleanup** - Optionally launches Windows Disk Cleanup with pre-vetted categories

---

## What This Tool Does NOT Do

- No registry modifications of any kind
- No driver installations or kernel-level changes
- No background services or persistent agents
- No automated deletions without explicit confirmation
- No telemetry, data collection, or phone-home behavior
- No promises of "speed boosts" or "performance improvements"

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Operating System | Windows 10 (version 1903+) or Windows 11 |
| PowerShell | Version 5.1 or later (built into Windows) |
| Privileges | Administrator recommended for full SMART data |

---

## Usage

### Interactive Mode (Default)

```powershell
.\JAB-DriveHygieneCheck.ps1
```

Launches an interactive menu where you can:
- View physical disk information
- Check volume status and free space
- Analyze SSD/TRIM configuration
- Scan for cleanup candidates
- Export reports
- Launch safe disk cleanup

### Quick Scan (No Prompts)

```powershell
.\JAB-DriveHygieneCheck.ps1 -QuickScan
```

Runs a complete scan and displays results without interactive prompts.

### Export Report

```powershell
# HTML Report (default)
.\JAB-DriveHygieneCheck.ps1 -ExportReport -OutputPath "C:\Reports"

# Text Report
.\JAB-DriveHygieneCheck.ps1 -ExportReport -OutputPath "C:\Reports" -ReportFormat Text

# Quick scan with HTML export
.\JAB-DriveHygieneCheck.ps1 -QuickScan -ExportReport
```

---

## Understanding the Output

### Health Status

| Status | Meaning |
|--------|---------|
| **Healthy** | Drive is operating normally |
| **Warning** | Issues detected - monitor closely |
| **Unhealthy** | Immediate attention required - back up data |

### TRIM Status

| Status | Meaning |
|--------|---------|
| **Enabled** | SSD optimization is working correctly |
| **Disabled** | May impact SSD performance and lifespan |

### Volume Status

| Status | Meaning |
|--------|---------|
| **Healthy** | More than 20% free space |
| **Warning** | Between 10-20% free space |
| **Critical** | Less than 10% free space |

---

## Safe Cleanup Categories

When you choose to launch Disk Cleanup, only these pre-vetted categories are recommended:

- Temporary Files
- Temporary Internet Files
- Thumbnails
- Delivery Optimization Files
- Windows Update Cleanup
- Downloaded Program Files
- Recycle Bin

**Categories we explicitly exclude** (too aggressive):
- System Restore Points
- Previous Windows Installations
- Device Driver Packages

You always make the final selection in the Windows Disk Cleanup dialog.

---

## Troubleshooting

### "Running scripts is disabled on this system"

PowerShell's execution policy is blocking the script. Run PowerShell as Administrator and execute:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then try running the script again.

### Limited information displayed

Some data (SMART status, reliability counters, temperature) requires administrator privileges. For complete results:

1. Right-click PowerShell
2. Select "Run as Administrator"
3. Navigate to the script location
4. Run the script

### "Get-PhysicalDisk not found"

This can occur on older Windows versions. The tool will automatically fall back to WMI methods, but some features may be limited.

---

## Privacy & Security

This tool is designed with transparency in mind:

- **No network connections** - The script never connects to the internet
- **No data collection** - Nothing is logged or transmitted
- **Fully inspectable** - The script is plain text PowerShell you can read
- **No persistence** - Nothing is installed, no services are created
- **Read-only by default** - Changes only happen when you explicitly confirm

---

## File Locations Analyzed

The tool inspects these locations for cleanup candidates:

| Category | Location |
|----------|----------|
| User Temp | `%TEMP%` |
| Windows Temp | `C:\Windows\Temp` |
| Prefetch | `C:\Windows\Prefetch` |
| Windows Update | `C:\Windows\SoftwareDistribution\Download` |
| Delivery Optimization | `C:\Windows\ServiceProfiles\...\DeliveryOptimization` |
| Chrome Cache | `%LOCALAPPDATA%\Google\Chrome\...\Cache` |
| Edge Cache | `%LOCALAPPDATA%\Microsoft\Edge\...\Cache` |
| Firefox Cache | `%LOCALAPPDATA%\Mozilla\Firefox\Profiles` |
| Recycle Bin | All drives |

---

## Example Output

```
  ═══════════════════════════════════════════════════════════════
   Physical Disks
  ═══════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────────────────────────
    │ Disk 0: Samsung SSD 970 EVO Plus 1TB
    ├─────────────────────────────────────────────────────────
      Type                      SSD
      Bus                       NVMe
      Size                      931.51 GB
      Health                    Healthy
      Status                    OK
    └─────────────────────────────────────────────────────────

  ═══════════════════════════════════════════════════════════════
   Volumes
  ═══════════════════════════════════════════════════════════════

    C: Windows
    [████████████████████████░░░░░░░░░░░░░░░░] 62.3% used
    Used: 580.12 GB / Total: 931.51 GB / Free: 351.39 GB
```

---

## Support

Questions or issues?

- **Website**: [jabsystems.io](https://jabsystems.io)
- **Email**: info@jabsystems.io

---

## License

MIT License - See [LICENSE](../../LICENSE) file for details.

---

## Related Tools

If you find this utility helpful, check out the **JAB Admin Toolkit** - a comprehensive administrative toolkit that includes this functionality plus:

- System health monitoring
- Network diagnostics
- SQL operations
- Application analysis
- And more

[Learn about JAB Admin Toolkit](https://jabsystems.io/tools/admin-toolkit/)
