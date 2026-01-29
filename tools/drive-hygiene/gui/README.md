# JAB Drive Hygiene Check - GUI

A minimal, professional GUI wrapper for the JAB Drive Hygiene Check PowerShell utility.

## Overview

This WPF application provides a clean, operator-focused interface for disk inspection while maintaining complete transparency. The GUI is a **presentation layer only** — all business logic remains in the auditable PowerShell script.

## Design Principles

1. **PowerShell is the source of truth** - GUI invokes PS and renders JSON output
2. **No business logic duplication** - GUI performs zero calculations
3. **No destructive actions** - No delete buttons, only launches Windows Disk Cleanup
4. **No telemetry** - 100% local operation
5. **Operator-first UX** - No wizards, no fake progress bars, no animations

## Features

### Inspect Screen
- Run system inspection
- Display trust indicators (read-only, no registry changes, no services)
- Show last run timestamp, duration, and privilege level
- Real progress text (no fake percentages)

### Results Screen
- System summary (computer, scan time, disk count, reclaimable space)
- Physical disks with health status
- Volumes with usage bars (color-coded: green/yellow/red)
- SSD/TRIM status
- Cleanup candidates breakdown
- "Open Windows Disk Cleanup" button

### Export Screen
- Format selection (HTML recommended, or Text)
- Output path selection
- Optional "Open after export"
- Explicit "no telemetry" notice

### About Screen
- Version information
- Guarantees (no telemetry, no services, MIT licensed)
- "View Script Source" button for transparency

## Requirements

- Windows 10 (≥1809) or Windows 11
- .NET 6 SDK (for building)
- PowerShell 5.1+ (included with Windows)

**Runtime**: Self-contained build requires no .NET installation

## Build Instructions

### Build Single-File EXE

```powershell
cd gui
.\build.ps1 -Configuration Release
```

Output: `build-gui/JABDriveHygiene.exe` (~60MB, self-contained)

### Development Build

```powershell
dotnet build
dotnet run
```

### Manual Publish

```powershell
dotnet publish `
    -c Release `
    -r win-x64 `
    --self-contained true `
    -p:PublishSingleFile=true `
    -o .\publish
```

## Project Structure

```
gui/
├── Models/
│   └── ScanResult.cs              # JSON schema models
├── Services/
│   └── PowerShellService.cs       # PowerShell invocation
├── App.xaml                       # Dark theme definitions
├── App.xaml.cs                    # Application entry
├── MainWindow.xaml                # UI layout (4 screens)
├── MainWindow.xaml.cs             # UI logic
├── JABDriveHygieneGUI.csproj      # Project file
├── build.ps1                      # Build script
├── DESIGN.md                      # Design documentation
└── README.md                      # This file
```

## PowerShell Integration

### Inspection Mode

The GUI invokes PowerShell with `-JsonOutput` flag:

```powershell
powershell.exe -ExecutionPolicy Bypass -NoProfile `
  -File "JAB-DriveHygieneCheck.ps1" -JsonOutput
```

PowerShell returns structured JSON to stdout, which the GUI parses and renders.

### Export Mode

```powershell
powershell.exe -ExecutionPolicy Bypass -NoProfile `
  -File "JAB-DriveHygieneCheck.ps1" `
  -ExportReport -ReportFormat HTML -OutputPath "C:\Reports"
```

### Disk Cleanup

Launches native Windows tool:

```powershell
cleanmgr.exe /D C
```

## JSON Schema

Example PowerShell output:

```json
{
  "Metadata": {
    "Version": "1.0.0",
    "Timestamp": "2025-01-29T10:30:00Z",
    "IsAdministrator": false,
    "ComputerName": "DESKTOP-ABC"
  },
  "PhysicalDisks": [...],
  "Volumes": [
    {
      "DriveLetter": "C:",
      "VolumeName": "System",
      "TotalSizeFormatted": "931.22 GB",
      "FreeSpaceFormatted": "419.09 GB",
      "PercentUsed": 55.0,
      "Status": "Healthy"
    }
  ],
  "TrimInfo": {
    "TrimEnabled": true,
    "Details": "TRIM is enabled (recommended for SSDs)"
  },
  "UsageBreakdown": [...],
  "Summary": {
    "TotalReclaimableFormatted": "5.29 GB",
    "CriticalVolumes": 0,
    "WarningVolumes": 0
  }
}
```

## Usage

1. Run `JABDriveHygiene.exe`
2. Click "Run Inspection" on the Inspect screen
3. View results (auto-navigates to Results screen)
4. Optionally export report (Export screen)
5. Optionally launch Windows Disk Cleanup from Results screen

## Design Decisions

### Why WPF?
- Built into .NET 6 (no extra dependencies)
- Superior text rendering
- Native dark theme support
- Can compile to single EXE

### Why Fixed Window Size (900×600)?
- Responsive layouts signal "consumer app"
- Fixed layouts signal "operator tool"
- Prevents layout bugs

### Why No MVVM?
- This is a presentation shell, not a complex application
- No business logic to test
- No state mutations
- Single scan result object
- MVVM would add complexity without benefit

### Why No Progress Percentage?
- PowerShell inspection has variable phases
- Can't predict duration accurately
- Real text ("Running system inspection...") beats fake percentages

### Why Dark Theme Only?
- Expected in operator tools
- Reduces decision fatigue
- Simpler CSS/XAML
- Matches PowerShell aesthetic

## Security

### No Destructive Actions
The GUI cannot:
- Delete files
- Modify registry
- Kill processes
- Change services

### No Network Access
- No update checks
- No telemetry
- No crash reporting
- 100% local operation

### PowerShell Execution
Uses `-ExecutionPolicy Bypass -NoProfile`:
- Script ships with EXE (user already trusts it)
- `-NoProfile` prevents profile script execution
- Clean environment every run

## Error Handling

Shows raw errors without abstraction:

```
Inspection failed:

PowerShell script failed with exit code 1.
Errors: Get-PhysicalDisk: Access denied
```

Operators can troubleshoot from real error messages.

## Distribution

Single EXE can be:
- Copied to USB drives
- Deployed via GPO
- Emailed (if org allows)
- Run from network shares

**No installer = no admin rights required for deployment**

## Troubleshooting

### "Script file not found"
Ensure `JAB-DriveHygieneCheck.ps1` is in the same directory as the EXE.

### "Access denied" errors
Some features (SMART data) require Administrator privileges. Right-click and "Run as Administrator".

### "Execution policy" errors
The GUI uses `-ExecutionPolicy Bypass` — this should not occur. If it does, check your Group Policy settings.

## License

MIT License - See LICENSE file

## Contact

JAB Systems
- Website: https://jabsystems.io
- Email: info@jabsystems.io

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                      User Interface                      │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐        │
│  │Inspect │  │Results │  │ Export │  │ About  │        │
│  └────────┘  └────────┘  └────────┘  └────────┘        │
└────────────────────────┬─────────────────────────────────┘
                         │
                         │ PowerShellService.RunInspectionAsync()
                         ▼
┌──────────────────────────────────────────────────────────┐
│              PowerShell Process Invocation               │
│  powershell.exe -File JAB-DriveHygieneCheck.ps1         │
│                 -JsonOutput                              │
└────────────────────────┬─────────────────────────────────┘
                         │
                         │ Structured JSON Output
                         ▼
┌──────────────────────────────────────────────────────────┐
│                   JSON Deserialization                   │
│  JsonSerializer.Deserialize<ScanResult>()               │
└────────────────────────┬─────────────────────────────────┘
                         │
                         │ ScanResult object
                         ▼
┌──────────────────────────────────────────────────────────┐
│                    Results Rendering                     │
│  - BuildSystemSummary()                                  │
│  - BuildPhysicalDisksView()                             │
│  - BuildVolumesView()                                    │
│  - BuildCleanupCandidatesView()                         │
└──────────────────────────────────────────────────────────┘
```

## Code Statistics

- **C# Code**: ~950 lines
- **XAML**: ~550 lines
- **Total**: ~1500 lines

Intentionally small and readable.

---

**Built by JAB Systems**
*Tools for operators, not consumers*
