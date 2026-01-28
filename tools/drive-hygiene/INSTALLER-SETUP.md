# JAB Drive Hygiene Check - Installer Setup Guide

## Overview

This guide walks you through building a professional Windows installer for JAB Drive Hygiene Check using NSIS.

## What You'll Get

- ✓ Professional Windows installer (.exe)
- ✓ Auto-installs to Program Files
- ✓ Creates Start Menu shortcuts
- ✓ Adds to Programs & Features (Control Panel)
- ✓ Clean uninstall with registry cleanup
- ✓ Branded with JAB Systems logo
- ✓ Code-sign ready

## Prerequisites

### Required Software

1. **NSIS (Nullsoft Scriptable Install System)**
   - **Download:** https://nsis.sourceforge.io/Download
   - **Version:** 3.10 or later
   - **Installation:** Default options are fine

2. **PowerShell 5.1+**
   - Windows 10/11 include this by default
   - Verify with: `$PSVersionTable.PSVersion`

### Optional but Recommended

- **Code signing certificate** (for production/enterprise distribution)
- **Custom installer graphics** (header.bmp, wizard.bmp for branding)

## Setup Instructions

### 1. Install NSIS

```powershell
# Download from: https://nsis.sourceforge.io/Download
# Run the installer with default options
# Default install location: C:\Program Files (x86)\NSIS
```

### 2. Prepare Files

Copy the following to your project directory:

```
your-project/
├── JAB-DriveHygieneCheck.ps1      # PowerShell script
├── JAB-DriveHygieneCheck.bat      # Batch launcher
├── README.md                      # Documentation
├── build-installer.ps1            # Build script
└── JAB-DriveHygieneCheck-Installer.nsi  # NSIS configuration
```

### 3. Run the Build Script

```powershell
# Navigate to project directory
cd "D:\Projects\JABSystems.io\tools\drive-hygiene"

# Run the build script
.\build-installer.ps1

# Output will be in ./build/ directory
```

**What the script does:**
1. Fixes any smart quotes in the PowerShell script
2. Compiles the .ps1 to a standalone .exe
3. Creates the NSIS installer package
4. Generates output files

## Output Files

After successful build, you'll have:

```
build/
├── JAB-DriveHygieneCheck.exe                          # Standalone executable
├── JAB-DriveHygieneCheck-1.0.0-installer.exe         # The installer (ready to distribute)
├── JAB-DriveHygieneCheck.ps1
├── JAB-DriveHygieneCheck.bat
├── README.md
└── LICENSE.txt
```

## How to Distribute

### For Direct Downloads

1. Host `JAB-DriveHygieneCheck-1.0.0-installer.exe` on your web server
2. Create a download button on your website pointing to this file
3. Users download and run the installer

### For GitHub Releases

```bash
# Upload to GitHub releases
git release create v1.0.0 ./build/JAB-DriveHygieneCheck-1.0.0-installer.exe
```

### For Internal Distribution

1. Share via file hosting (Dropbox, OneDrive, etc.)
2. Include in email with installation instructions
3. Place on internal network share

## Installation Experience

When users run the installer, they'll see:

1. **Welcome Screen**
   - Introduces JAB Drive Hygiene Check
   - Shows license option

2. **License Agreement**
   - Displays MIT License
   - User must accept to continue

3. **Installation Directory**
   - Default: `C:\Program Files\JAB Systems\Drive Hygiene Check`
   - User can change if desired

4. **Installation Progress**
   - Shows files being installed
   - Estimated completion time

5. **Completion Screen**
   - Option to run the tool immediately
   - Link to JAB Systems website

## Post-Installation

After installation, users will have:

- **Start Menu:** JAB Drive Hygiene Check shortcut
- **Desktop:** Shortcut (if selected)
- **Programs & Features:** Listed for easy uninstall
- **File Location:** `C:\Program Files\JAB Systems\Drive Hygiene Check`

### Users Can Now:

```powershell
# Run directly by name
JAB-DriveHygieneCheck

# Or navigate to install location
cd "C:\Program Files\JAB Systems\Drive Hygiene Check"
.\JAB-DriveHygieneCheck.exe
```

## Uninstallation

Users can uninstall via:

1. **Control Panel** → Programs & Features → Uninstall
2. **Start Menu** → JAB Systems folder → Uninstall shortcut
3. **Direct:** `"C:\Program Files\JAB Systems\Drive Hygiene Check\uninstall.exe"`

## Customization

### Change Installation Directory

Edit `JAB-DriveHygieneCheck-Installer.nsi`:

```nsis
; Change this line:
!define INSTALL_DIR "$PROGRAMFILES\JAB Systems\Drive Hygiene Check"

; To something like:
!define INSTALL_DIR "$PROGRAMFILES\Your Company Name\Drive Hygiene Check"
```

### Add Custom Graphics

Add your branding images to the installer:

1. **header.bmp** - 150x57 pixels (top right header)
2. **wizard.bmp** - 164x314 pixels (left sidebar)

Then uncomment in `.nsi`:

```nsis
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "wizard.bmp"
```

### Code Signing (Enterprise)

To sign the installer:

```powershell
# After NSIS creates the installer
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert

Set-AuthenticodeSignature -FilePath "build\JAB-DriveHygieneCheck-1.0.0-installer.exe" `
                         -Certificate $cert `
                         -TimestampServer "http://timestamp.comodoca.com/authenticode"
```

## Troubleshooting

### "NSIS compiler not found"

**Solution:** Make sure NSIS is installed in one of these locations:
- `C:\Program Files (x86)\NSIS\makensis.exe`
- `C:\Program Files\NSIS\makensis.exe`

### "Smart quotes still breaking the script"

**Solution:** The build script automatically fixes these. If issues persist:

```powershell
# Run the fix-quotes.ps1 script separately
.\fix-quotes.ps1 -FilePath "JAB-DriveHygieneCheck.ps1"
```

### Installer won't run due to UAC

This is normal. Inform users that they may see a Windows security prompt—click "More info" → "Run anyway"

### Old version still shows in Programs & Features

When updating to a new version:
1. Increment the version number in `build-installer.ps1`
2. Rebuild the installer
3. New installer will prompt to remove old version

## Version Updates

To build a new version:

1. Update version in `JAB-DriveHygieneCheck.ps1`:
   ```powershell
   $Script:Version = "1.1.0"
   ```

2. Update version in `build-installer.ps1`:
   ```powershell
   $Version = "1.1.0"
   ```

3. Run build script:
   ```powershell
   .\build-installer.ps1
   ```

4. Test the new installer thoroughly

5. Distribute the new `JAB-DriveHygieneCheck-1.1.0-installer.exe`

## Testing Checklist

Before distributing, verify:

- [ ] Installer runs without errors
- [ ] Installs to correct directory
- [ ] Creates Start Menu shortcuts
- [ ] Shortcut launches the application
- [ ] Application runs correctly after installation
- [ ] Uninstall option appears in Programs & Features
- [ ] Uninstall removes all files and shortcuts
- [ ] Reinstalling doesn't create duplicates
- [ ] Works on both standard user and admin accounts

## Support Resources

- **NSIS Documentation:** https://nsis.sourceforge.io/Docs/
- **JAB Systems:** https://jabsystems.io
- **NSIS Tutorial:** https://nsis.sourceforge.io/Simple_tutorials

## Consistency Across Products

This installer follows the same pattern as your Admin Toolkit:

✓ Same installation directory structure  
✓ Same Start Menu organization  
✓ Same registry cleanup approach  
✓ Same uninstall behavior  
✓ Same branding (JAB Systems)

To keep future tools consistent, copy this setup as a template.

---

**Version:** 1.0.0  
**Last Updated:** January 2026  
**Maintained by:** JAB Systems
