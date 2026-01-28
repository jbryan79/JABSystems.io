; JAB Drive Hygiene Check - NSIS Installer
; Professional Windows Installer
; Version 1.0.0

;================================
; CONFIGURATION
;================================

; MUI Modern User Interface
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"

; Product Definition
!define PRODUCT_NAME "JAB Drive Hygiene Check"
!define PRODUCT_VERSION "1.0.0"
!define PRODUCT_PUBLISHER "JAB Systems"
!define PRODUCT_WEB_SITE "https://jabsystems.io"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\JAB-DriveHygieneCheck.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; Installation Path
!define INSTALL_DIR "$PROGRAMFILES\JAB Systems\Drive Hygiene Check"

; Installer Attributes
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "build\JAB-DriveHygieneCheck-${PRODUCT_VERSION}-installer.exe"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "InstallLocation"
ShowInstDetails show
ShowUnInstDetails show

; Request Admin Privileges
RequestExecutionLevel admin

; Compression
SetCompressor /FINAL /SOLID lzma
SetDatablockOptimize on

;================================
; MUI SETTINGS
;================================

; MUI Settings
!define MUI_ABORTWARNING
; Icon files
!define MUI_ICON "jab-icon.ico"
!define MUI_UNICON "jab-icon.ico"
; Custom bitmaps (optional - comment out if not available)
; !define MUI_HEADERIMAGE
; !define MUI_HEADERIMAGE_RIGHT
; !define MUI_HEADERIMAGE_BITMAP "header.bmp"
; !define MUI_WELCOMEFINISHPAGE_BITMAP "wizard.bmp"

; Language
!insertmacro MUI_LANGUAGE "English"

;================================
; PAGES
;================================

; Welcome Page
!insertmacro MUI_PAGE_WELCOME

; License Page
!insertmacro MUI_PAGE_LICENSE "build\LICENSE.txt"

; Directory Page
!insertmacro MUI_PAGE_DIRECTORY

; Installation Page
!insertmacro MUI_PAGE_INSTFILES

; Finish Page
!define MUI_FINISHPAGE_RUN "$INSTDIR\JAB-DriveHygieneCheck.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Run JAB Drive Hygiene Check"
!define MUI_FINISHPAGE_LINK "Visit JAB Systems Website"
!define MUI_FINISHPAGE_LINK_LOCATION "${PRODUCT_WEB_SITE}"
!insertmacro MUI_PAGE_FINISH

; Uninstaller Pages
!insertmacro MUI_UNPAGE_INSTFILES

;================================
; INSTALLER SECTIONS
;================================

Section "Install" SEC01
  SetOutPath "$INSTDIR"
  SetOverwrite try

  ; Main Files
  File "build\JAB-DriveHygieneCheck.exe"
  File "build\JAB-DriveHygieneCheck.ps1"
  File "build\JAB-DriveHygieneCheck.bat"
  File "build\README.md"
  File "build\LICENSE.txt"

  ; Create Uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

SectionEnd

;================================
; REGISTRY & SHORTCUTS
;================================

Section -Post
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\JAB-DriveHygieneCheck.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"

  ; Create Start Menu Folder
  CreateDirectory "$SMPROGRAMS\JAB Systems"
  CreateShortCut "$SMPROGRAMS\JAB Systems\JAB Drive Hygiene Check.lnk" "$INSTDIR\JAB-DriveHygieneCheck.exe"
  CreateShortCut "$SMPROGRAMS\JAB Systems\Uninstall Drive Hygiene Check.lnk" "$INSTDIR\uninstall.exe"

  ; Create Desktop Shortcut (Optional)
  CreateShortCut "$DESKTOP\JAB Drive Hygiene Check.lnk" "$INSTDIR\JAB-DriveHygieneCheck.exe"

SectionEnd

;================================
; UNINSTALLER
;================================

Section Uninstall
  ; Remove Files
  Delete "$INSTDIR\JAB-DriveHygieneCheck.exe"
  Delete "$INSTDIR\JAB-DriveHygieneCheck.ps1"
  Delete "$INSTDIR\JAB-DriveHygieneCheck.bat"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\LICENSE.txt"
  Delete "$INSTDIR\uninstall.exe"

  ; Remove Directory
  RMDir "$INSTDIR"

  ; Remove Start Menu Shortcuts
  Delete "$SMPROGRAMS\JAB Systems\JAB Drive Hygiene Check.lnk"
  Delete "$SMPROGRAMS\JAB Systems\Uninstall Drive Hygiene Check.lnk"
  RMDir "$SMPROGRAMS\JAB Systems"

  ; Remove Desktop Shortcut
  Delete "$DESKTOP\JAB Drive Hygiene Check.lnk"

  ; Remove Registry
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"

SectionEnd

;================================
; LANGUAGE STRINGS
;================================

LangString ^UninstallCaption ${LANG_ENGLISH} "${PRODUCT_NAME} - Uninstall"
LangString ^UninstallSubCaption ${LANG_ENGLISH} "Remove ${PRODUCT_NAME} from your computer."
