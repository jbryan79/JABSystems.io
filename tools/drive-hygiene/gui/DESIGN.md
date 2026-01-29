# JAB Drive Hygiene Check - GUI Design Documentation

## Executive Summary

This GUI wrapper transforms the JAB Drive Hygiene Check PowerShell utility into a credible product artifact while maintaining complete transparency and operational restraint.

**Technology**: WPF (.NET 6+)
**Target Platform**: Windows 10/11
**Output**: Single self-contained EXE (~60MB)
**Window Size**: 900×600 (fixed)
**Theme**: Dark only

## Design Philosophy

Every design decision follows three principles:

1. **Operator Trust** - No hidden behavior, no clever abstractions
2. **Transparency** - PowerShell remains visible and auditable
3. **Restraint** - No features beyond presentation and orchestration

This tool is designed for experienced operators, not casual users.

## Architecture

### High-Level Flow

```
┌─────────────────┐
│   WPF GUI       │
│  (Presentation) │
└────────┬────────┘
         │
         │ Invokes with -JsonOutput
         ▼
┌─────────────────┐
│   PowerShell    │
│   (Business     │
│    Logic)       │
└────────┬────────┘
         │
         │ Returns structured JSON
         ▼
┌─────────────────┐
│   WPF GUI       │
│  (Renders       │
│   Results)      │
└─────────────────┘
```

### Component Breakdown

```
JABDriveHygieneGUI/
├── Models/
│   └── ScanResult.cs          # JSON schema models (read-only)
├── Services/
│   └── PowerShellService.cs   # PowerShell invocation only
├── Views/
│   └── (Embedded in MainWindow.xaml)
├── App.xaml                   # Theme/styles
├── MainWindow.xaml            # Navigation + 4 screens
└── MainWindow.xaml.cs         # UI logic only
```

**No ViewModels. No MVVM. No state management beyond last scan result.**

## PowerShell ↔ GUI Contract

### GUI → PowerShell

The GUI invokes PowerShell in exactly two modes:

**1. Inspection Mode**
```powershell
powershell.exe -ExecutionPolicy Bypass -NoProfile `
  -File "JAB-DriveHygieneCheck.ps1" -JsonOutput
```

**2. Export Mode**
```powershell
powershell.exe -ExecutionPolicy Bypass -NoProfile `
  -File "JAB-DriveHygieneCheck.ps1" `
  -ExportReport -ReportFormat HTML -OutputPath "C:\Reports"
```

### PowerShell → GUI

PowerShell returns structured JSON to stdout:

```json
{
  "Metadata": {
    "Version": "1.0.0",
    "Timestamp": "2025-01-29T10:30:00Z",
    "IsAdministrator": false,
    "ComputerName": "DESKTOP-ABC123"
  },
  "PhysicalDisks": [
    {
      "DeviceId": 0,
      "FriendlyName": "Samsung SSD 980 PRO 1TB",
      "MediaType": "SSD",
      "BusType": "NVMe",
      "HealthStatus": "Healthy",
      "OperationalStatus": "Online",
      "Size": 1000204886016,
      "SizeFormatted": "931.51 GB"
    }
  ],
  "SmartData": [...],
  "Volumes": [
    {
      "DriveLetter": "C:",
      "VolumeName": "System",
      "FileSystem": "NTFS",
      "TotalSize": 999889567744,
      "TotalSizeFormatted": "931.22 GB",
      "FreeSpace": 450000000000,
      "FreeSpaceFormatted": "419.09 GB",
      "UsedSpace": 549889567744,
      "UsedSpaceFormatted": "512.13 GB",
      "PercentUsed": 55.0,
      "PercentFree": 45.0,
      "Status": "Healthy"
    }
  ],
  "TrimInfo": {
    "TrimEnabled": true,
    "RawOutput": "NTFS DisableDeleteNotify = 0",
    "Details": "TRIM is enabled (recommended for SSDs)"
  },
  "UsageBreakdown": [
    {
      "Category": "User Temp Files",
      "Path": "C:\\Users\\...\\AppData\\Local\\Temp",
      "Size": 1234567890,
      "SizeFormatted": "1.15 GB",
      "FileCount": 4532
    }
  ],
  "Summary": {
    "TotalPhysicalDisks": 1,
    "TotalVolumes": 2,
    "TotalReclaimableBytes": 5678901234,
    "TotalReclaimableFormatted": "5.29 GB",
    "CriticalVolumes": 0,
    "WarningVolumes": 0
  }
}
```

**Contract Guarantees:**
- GUI never performs calculations
- GUI never infers status
- GUI never modifies data
- GUI only renders what PowerShell provides

## Screen Specifications

### 1. Inspect (Default)

**Purpose**: Initiate inspection and display trust indicators

**Layout**:
```
┌─────────────────────────────────────┐
│ System Inspection                   │
│ Read-only disk and volume analysis  │
├─────────────────────────────────────┤
│                                     │
│ ┌─ TRUST INDICATORS ──────────────┐│
│ │ ✔ Read-only operations          ││
│ │ ✔ No registry changes           ││
│ │ ✔ No background services        ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─ LAST RUN ──────────────────────┐│
│ │ Timestamp: 2025-01-29 10:30:00  ││
│ │ Duration:  12.3s                ││
│ │ Privilege: Standard User        ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─────────────────────────┐        │
│ │   Run Inspection        │        │
│ └─────────────────────────┘        │
└─────────────────────────────────────┘
```

**Progress Indication**:
- No fake progress bars
- Real phase text only: "Running system inspection..."

**UX Notes**:
- Button disabled during scan
- No animations or spinners
- No estimated time remaining

### 2. Results

**Purpose**: Display structured inspection data

**Layout**:
```
┌─────────────────────────────────────┐
│ Inspection Results                  │
├─────────────────────────────────────┤
│                                     │
│ ┌─ SYSTEM SUMMARY ────────────────┐│
│ │ Computer:       DESKTOP-ABC123  ││
│ │ Scan Time:      2025-01-29...   ││
│ │ Physical Disks: 1               ││
│ │ Volumes:        2               ││
│ │ Reclaimable:    5.29 GB         ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─ PHYSICAL DISKS ────────────────┐│
│ │ Disk 0: Samsung SSD 980 PRO 1TB ││
│ │   Type:   SSD                   ││
│ │   Size:   931.51 GB             ││
│ │   Health: Healthy ✓             ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─ VOLUMES ───────────────────────┐│
│ │ C: System (NTFS)                ││
│ │ [████████──────────] 55% used   ││
│ │ 512 GB used of 931 GB (45% free)││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─ CLEANUP CANDIDATES ────────────┐│
│ │ Total: 5.29 GB                  ││
│ │ User Temp Files        1.15 GB  ││
│ │ Windows Update Cache   2.34 GB  ││
│ │ Recycle Bin           1.80 GB  ││
│ │ ───────────────────────────────  ││
│ │ [Open Windows Disk Cleanup]     ││
│ └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

**Volume Status Bar**:
- Green: Healthy (>20% free)
- Yellow: Warning (10-20% free)
- Red: Critical (<10% free)
- Simple solid color fill, no gradients

**UX Notes**:
- No expandable rows (YAGNI)
- All data visible on first render
- Single "Open Windows Disk Cleanup" button
- No inline "Delete" actions

### 3. Export

**Purpose**: Generate local report files

**Layout**:
```
┌─────────────────────────────────────┐
│ Export Report                       │
├─────────────────────────────────────┤
│                                     │
│ ┌─ FORMAT SELECTION ──────────────┐│
│ │ ○ HTML Report (recommended)     ││
│ │ ○ Text Report                   ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─ OUTPUT LOCATION ───────────────┐│
│ │ C:\Users\...\Documents          ││
│ │                   [Browse...]   ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─────────────────────────────────┐│
│ │ ☑ Open report after export      ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─────────────────────────────────┐│
│ │ NOTE: Reports are generated     ││
│ │ locally and contain no          ││
│ │ telemetry or tracking.          ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─────────────────────────┐        │
│ │   Export Report         │        │
│ └─────────────────────────┘        │
└─────────────────────────────────────┘
```

**UX Notes**:
- HTML is default (better rendering)
- No cloud upload options
- No email integration
- Explicit "local only" note

### 4. About

**Purpose**: Version info and guarantees

**Layout**:
```
┌─────────────────────────────────────┐
│ About                               │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐│
│ │ JAB DRIVE HYGIENE CHECK         ││
│ │ Version 1.0.0                   ││
│ │                                 ││
│ │ A Windows disk inspection       ││
│ │ utility that analyzes drive     ││
│ │ health, SMART status, SSD       ││
│ │ optimization, and disk usage.   ││
│ │                                 ││
│ │ https://jabsystems.io           ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─ GUARANTEES ────────────────────┐│
│ │ ✓ No telemetry or data          ││
│ │   collection                    ││
│ │ ✓ No persistent background      ││
│ │   services                      ││
│ │ ✓ MIT License - Open source     ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌────────────────────────┐         │
│ │ View Script Source     │         │
│ └────────────────────────┘         │
└─────────────────────────────────────┘
```

**"View Script Source" Button**:
- Opens `JAB-DriveHygieneCheck.ps1` in default editor
- Demonstrates transparency
- No obfuscation, no compiled logic

## Design Decisions

### Why WPF?

**Considered**: WinForms, WPF, WinUI 3

**Chosen**: WPF

**Rationale**:
- Built into .NET 6+ (no extra dependencies)
- Superior text rendering vs WinForms
- XAML enables clean separation
- Native dark theme support
- Can compile to single EXE
- WinUI 3 rejected (too new, more complex)

### Why No MVVM?

This is a **presentation shell**, not a complex application.

- No business logic to test
- No state mutations
- No computed properties
- Single scan result object

MVVM would add complexity without benefit.

### Why Fixed Window Size?

Responsive layouts signal "consumer app".
Fixed layouts signal "operator tool".

900×600 works on all displays ≥1024×768 and prevents layout bugs.

### Why Dark Theme Only?

- Expected in operator tools
- Reduces decision fatigue (no theme toggle)
- Simpler CSS/XAML
- Matches PowerShell console aesthetic

### Why No Progress Percentage?

Progress percentages are lies when you don't know the actual work.

PowerShell inspection has variable phases:
- Disk enumeration: 0.5s
- SMART data: 2-5s (requires admin)
- Usage analysis: 3-30s (depends on file count)

**Real text beats fake percentages**:
- ✗ "45% complete"
- ✓ "Running system inspection..."

## Error Handling

**Principle**: Show raw errors, don't abstract them.

**Example**:
```
Inspection failed:

PowerShell script failed with exit code 1.
Errors: Get-PhysicalDisk: Access denied
```

**Rationale**:
- Operators can troubleshoot
- No "Something went wrong" nonsense
- Exposes privilege issues clearly

## Security Considerations

### No Destructive Actions

The GUI cannot:
- Delete files
- Modify registry
- Kill processes
- Change services

It can only:
- Read PowerShell output
- Launch `cleanmgr.exe` (Windows native)
- Open text files

### No Network Access

- No update checks
- No telemetry
- No crash reporting
- No analytics

100% local operation.

### PowerShell Execution Policy

```powershell
-ExecutionPolicy Bypass -NoProfile
```

**Bypass is intentional**:
- Tool ships with script in same directory
- User already trusts the EXE
- Avoids "can't run scripts" support issues

**-NoProfile protects users**:
- Won't execute profile scripts
- Clean environment every run

## Build & Distribution

### Build Command

```powershell
.\build.ps1 -Configuration Release
```

Produces:
- `JABDriveHygiene.exe` (~60MB, self-contained)
- Embedded `JAB-DriveHygieneCheck.ps1`
- No installer, no dependencies

### Why Self-Contained?

Users may not have .NET 6 installed.

Self-contained = zero prerequisites.

### Distribution

Single EXE can be:
- Copied to USB drives
- Deployed via GPO
- Emailed (if org allows)
- Run from network shares

No installer = no admin rights required for deployment.

## Testing Checklist

- [ ] Run on Windows 10 (≥1809)
- [ ] Run on Windows 11
- [ ] Run as Standard User
- [ ] Run as Administrator
- [ ] Test with no volumes to clean
- [ ] Test with critical volumes
- [ ] Export HTML report
- [ ] Export Text report
- [ ] Launch Disk Cleanup
- [ ] View Script Source
- [ ] Resize window (should be blocked)

## Maintenance Notes

### To Add a New Screen

1. Add XML to `MainWindow.xaml` (Grid with `x:Name`)
2. Add navigation button
3. Wire up Click handler
4. Update `ShowView()` to hide new screen

**Don't**:
- Create UserControls (overkill)
- Add routing frameworks (overkill)

### To Modify PowerShell Contract

1. Update PowerShell JSON output
2. Update `Models/ScanResult.cs`
3. Update rendering logic in `MainWindow.xaml.cs`

**Verify JSON schema matches exactly.**

### To Change Theme

All colors defined in `App.xaml`:
```xml
<Color x:Key="BackgroundColor">#FF0B0F14</Color>
<Color x:Key="AccentColor">#FF3AA0FF</Color>
```

No hardcoded colors in `MainWindow.xaml`.

## File Manifest

```
gui/
├── Models/
│   └── ScanResult.cs              # JSON schema (210 lines)
├── Services/
│   └── PowerShellService.cs       # PS invocation (180 lines)
├── App.xaml                       # Theme definitions (150 lines)
├── App.xaml.cs                    # Entry point (10 lines)
├── MainWindow.xaml                # All screens (400 lines)
├── MainWindow.xaml.cs             # UI logic (550 lines)
├── JABDriveHygieneGUI.csproj      # Project file
├── build.ps1                      # Build script
└── DESIGN.md                      # This file
```

**Total C# code**: ~950 lines
**Total XAML**: ~550 lines
**Total**: ~1500 lines

**This is intentionally small.**

## Why This Design Works

1. **Operator trust**: View Source button, no hidden logic
2. **Transparency**: PowerShell does all work, GUI just renders
3. **Restraint**: No features beyond "run, view, export"
4. **Professionalism**: Fixed layout, dark theme, no cutesy animations
5. **Auditability**: 1500 lines total, readable in 30 minutes

This doesn't feel like a consumer app.
It feels like a tool built by people who respect their users.

---

*JAB Systems | https://jabsystems.io*
