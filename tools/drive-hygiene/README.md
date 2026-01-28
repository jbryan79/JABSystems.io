<p align="center">
  <img src="../../assets/jab-logo.png" alt="JAB Systems" width="80">
</p>

<h1 align="center">JAB Drive Hygiene Check</h1>

<p align="center">
  <strong>Safe, read-only disk inspection and cleanup for Windows</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#usage">Usage</a> •
  <a href="#understanding-results">Results</a> •
  <a href="#faq">FAQ</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%2010%2F11-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/Version-1.0.0-orange?style=flat-square" alt="Version">
</p>

---

## Why This Tool?

Most disk utilities promise speed boosts, modify your registry, or run background services. **We built something different.**

JAB Drive Hygiene Check is a **transparent, read-only inspection tool** that shows you exactly what's happening with your storage—without making changes you didn't ask for.

> *"Inspection first. Action second. Always transparent."*

---

## Features

| Feature | Description |
|---------|-------------|
| **Disk Health** | SMART status monitoring across all connected drives |
| **SSD Analysis** | TRIM status, optimization state, and wear indicators |
| **Space Breakdown** | Visual breakdown of what's consuming your storage |
| **Cleanup Finder** | Identifies temp files, caches, and safe-to-remove items |
| **Safe Cleanup** | Launches native Windows tools with pre-vetted categories |
| **Export Reports** | Generate HTML or text reports for documentation |

### What We Don't Do

- No registry modifications
- No driver installations
- No background services
- No automatic deletions
- No telemetry or data collection
- No "speed boost" promises

---

## Quick Start

### Option 1: Double-Click Launcher *(Recommended)*

```
1. Download the tool package
2. Double-click JAB-DriveHygieneCheck.bat
3. Done — the tool opens automatically
```

### Option 2: PowerShell Direct

```powershell
.\JAB-DriveHygieneCheck.ps1
```

> **Tip:** Right-click and select "Run as Administrator" for complete SMART data and temperature readings.

---

## Usage

### Interactive Mode

Launch the tool and use the menu to navigate:

```
╔═══════════════════════════════════════════════════════════════╗
║                        MAIN MENU                              ║
╠═══════════════════════════════════════════════════════════════╣
║   [1]  View Physical Disk Information                         ║
║   [2]  View Volume Status                                     ║
║   [3]  View SSD/TRIM Status                                   ║
║   [4]  Analyze Cleanup Candidates                             ║
║   [5]  Run Full Scan                                          ║
║   [6]  Launch Safe Disk Cleanup                               ║
║   [7]  Export Report                                          ║
║   [Q]  Quit                                                   ║
╚═══════════════════════════════════════════════════════════════╝
```

### Command Line Options

| Command | Description |
|---------|-------------|
| `.\JAB-DriveHygieneCheck.ps1` | Interactive mode |
| `.\JAB-DriveHygieneCheck.ps1 -QuickScan` | Run full scan, no prompts |
| `.\JAB-DriveHygieneCheck.ps1 -ExportReport` | Scan and save HTML report |
| `.\JAB-DriveHygieneCheck.ps1 -ExportReport -ReportFormat Text` | Save as text file |
| `.\JAB-DriveHygieneCheck.ps1 -QuickScan -ExportReport -OutputPath "C:\Reports"` | Combined options |

---

## Understanding Results

### Health Status

| Status | Indicator | Meaning |
|--------|-----------|---------|
| **Healthy** | 🟢 | Drive operating normally |
| **Warning** | 🟡 | Issues detected — monitor closely |
| **Unhealthy** | 🔴 | Immediate attention required |

### Volume Space

The tool displays visual progress bars for each volume:

```
C: Windows
[████████████████████████░░░░░░░░░░░░░░░░] 62.3% used
Used: 580.12 GB / Total: 931.51 GB / Free: 351.39 GB
```

| Free Space | Status | Action |
|------------|--------|--------|
| > 20% | Healthy | No action needed |
| 10-20% | Warning | Consider cleanup |
| < 10% | Critical | Cleanup recommended |

### TRIM Status (SSDs)

| Status | Meaning |
|--------|---------|
| **Enabled** | SSD optimization working correctly |
| **Disabled** | May impact performance and lifespan |

---

## Cleanup Categories

When you launch Safe Cleanup, only these **pre-vetted categories** are recommended:

**Included (Safe):**
- Temporary Files
- Temporary Internet Files
- Thumbnails
- Delivery Optimization Files
- Windows Update Cleanup
- Downloaded Program Files
- Recycle Bin

**Excluded (Too Aggressive):**
- System Restore Points
- Previous Windows Installations
- Device Driver Packages

> **Note:** You always make the final selection in Windows Disk Cleanup. Nothing is deleted without your explicit confirmation.

---

## Locations Analyzed

The tool inspects these common storage consumers:

| Category | Location |
|----------|----------|
| User Temp | `%TEMP%` |
| Windows Temp | `C:\Windows\Temp` |
| Prefetch | `C:\Windows\Prefetch` |
| Windows Update | `C:\Windows\SoftwareDistribution\Download` |
| Delivery Optimization | System cache folder |
| Chrome Cache | `%LOCALAPPDATA%\Google\Chrome\...\Cache` |
| Edge Cache | `%LOCALAPPDATA%\Microsoft\Edge\...\Cache` |
| Firefox Cache | `%LOCALAPPDATA%\Mozilla\Firefox\Profiles` |
| Recycle Bin | All drives |

---

## System Requirements

| Requirement | Specification |
|-------------|---------------|
| **OS** | Windows 10 (1903+) or Windows 11 |
| **PowerShell** | 5.1 or later (included with Windows) |
| **Privileges** | Standard user (Admin recommended for full data) |
| **Storage** | Minimal (~50 KB for script) |

---

## Troubleshooting

### "Running scripts is disabled on this system"

PowerShell's execution policy is blocking the script. **Solution:**

```powershell
# Option 1: Use the .bat launcher (bypasses this automatically)

# Option 2: Set policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Limited SMART Data

Some information (temperature, wear level, error counts) requires administrator privileges.

**Solution:** Right-click the launcher and select "Run as Administrator"

### "Get-PhysicalDisk not found"

This occurs on older Windows versions. The tool automatically falls back to WMI methods, but some features may be limited.

**Solution:** Update to Windows 10 version 1903 or later

---

## FAQ

<details>
<summary><strong>Is this tool safe to run?</strong></summary>

Yes. The tool is read-only by default and makes no changes to your system. The only action that modifies anything is the optional "Safe Cleanup" feature, which simply launches Windows' built-in Disk Cleanup utility—you still make the final decisions there.

</details>

<details>
<summary><strong>Does this tool connect to the internet?</strong></summary>

No. The script runs entirely offline. There is no telemetry, no update checks, and no data transmitted anywhere.

</details>

<details>
<summary><strong>Can I inspect the code before running?</strong></summary>

Absolutely. The tool is a plain-text PowerShell script. Open `JAB-DriveHygieneCheck.ps1` in any text editor to review exactly what it does.

</details>

<details>
<summary><strong>Why do I need admin rights for some features?</strong></summary>

Windows restricts access to certain hardware information (SMART data, temperature sensors, reliability counters) to administrator accounts. The tool works without admin—you just get less detailed hardware information.

</details>

<details>
<summary><strong>Will this speed up my computer?</strong></summary>

We don't make that promise. This tool helps you understand your storage situation and identify cleanup candidates. Whether cleanup improves perceived performance depends on your specific situation.

</details>

---

## Privacy & Security

| Aspect | Guarantee |
|--------|-----------|
| **Network** | No internet connections |
| **Data Collection** | None — no telemetry |
| **Persistence** | No services, no scheduled tasks |
| **Code** | Fully readable PowerShell |
| **Changes** | Read-only unless you explicitly confirm cleanup |

---

## Support

**Website:** [jabsystems.io](https://jabsystems.io)
**Email:** info@jabsystems.io

---

## Related Tools

Looking for more comprehensive system administration? Check out the **[JAB Admin Toolkit](https://jabsystems.io/tools/admin-toolkit/)** — our full-featured administrative suite including:

- System health monitoring
- Network diagnostics
- SQL operations
- Application analysis
- And more

---

<p align="center">
  <sub>Built by <a href="https://jabsystems.io">JAB Systems</a> — Enterprise tools built by operators, for operators.</sub>
</p>
