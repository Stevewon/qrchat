@echo off
REM ###########################################################################
REM QRChat Desktop - Automated Windows Code Signing Script
REM 
REM This script automates the entire Windows code signing process:
REM 1. Build Flutter app
REM 2. Sign the executable
REM 3. Create NSIS installer
REM 4. Sign the installer
REM
REM Requirements:
REM - Windows 10/11
REM - Flutter SDK
REM - Windows SDK (for signtool.exe)
REM - NSIS (for installer creation)
REM - Code signing certificate (.pfx file)
REM
REM Usage:
REM   sign_windows.bat
REM
REM Environment variables (set these before running):
REM   PFX_FILE          Path to .pfx certificate file
REM   PFX_PASSWORD      Password for .pfx file
REM   TIMESTAMP_URL     Timestamp server URL (default: Sectigo)
REM
REM ###########################################################################

setlocal enabledelayedexpansion

REM Configuration
set APP_NAME=qrchat
set APP_VERSION=2.0.0
set BUILD_MODE=release

REM Paths
set PROJECT_ROOT=%~dp0
set APP_PATH=%PROJECT_ROOT%build\windows\x64\runner\Release\%APP_NAME%.exe
set INSTALLER_NAME=QRChat-%APP_VERSION%-Setup.exe

REM Default values
if "%PFX_FILE%"=="" set PFX_FILE=qrchat.pfx
if "%TIMESTAMP_URL%"=="" set TIMESTAMP_URL=http://timestamp.sectigo.com

REM Find signtool.exe
set SIGNTOOL=
for /f "tokens=*" %%i in ('dir /b /s "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe" 2^>nul') do (
    set SIGNTOOL=%%i
    goto :found_signtool
)

:found_signtool
if "%SIGNTOOL%"=="" (
    echo [ERROR] signtool.exe not found
    echo Install Windows SDK from: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
    exit /b 1
)

echo.
echo ========================================================================
echo  QRChat Windows Code Signing Automation
echo ========================================================================
echo.

REM Check environment variables
if "%PFX_PASSWORD%"=="" (
    echo [ERROR] PFX_PASSWORD environment variable not set
    echo Set it with: set PFX_PASSWORD=your_password
    exit /b 1
)

if not exist "%PFX_FILE%" (
    echo [ERROR] Certificate file not found: %PFX_FILE%
    exit /b 1
)

echo [INFO] Using certificate: %PFX_FILE%
echo [INFO] Using signtool: %SIGNTOOL%
echo.

REM Check required tools
echo [INFO] Checking required tools...

where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter not found. Install from: https://flutter.dev
    exit /b 1
)

where makensis >nul 2>&1
if errorlevel 1 (
    echo [WARNING] NSIS not found. Installer creation will be skipped.
    echo Install from: https://nsis.sourceforge.io/Download
    set SKIP_INSTALLER=1
)

echo [SUCCESS] All tools available
echo.

REM Build Flutter app
echo [INFO] Building Flutter Windows app...
cd /d "%PROJECT_ROOT%"

call flutter clean
call flutter pub get
call flutter build windows --release

if not exist "%APP_PATH%" (
    echo [ERROR] Build failed: %APP_PATH% not found
    exit /b 1
)

echo [SUCCESS] Flutter build completed
echo.

REM Sign executable
echo [INFO] Signing executable...

"%SIGNTOOL%" sign ^
    /f "%PFX_FILE%" ^
    /p "%PFX_PASSWORD%" ^
    /tr "%TIMESTAMP_URL%" ^
    /td SHA256 ^
    /fd SHA256 ^
    /d "QRChat" ^
    /du "https://qrchat.io" ^
    /v ^
    "%APP_PATH%"

if errorlevel 1 (
    echo [ERROR] Failed to sign executable
    exit /b 1
)

echo [SUCCESS] Executable signed
echo.

REM Verify signature
echo [INFO] Verifying signature...

"%SIGNTOOL%" verify /pa /v "%APP_PATH%"

if errorlevel 1 (
    echo [ERROR] Signature verification failed
    exit /b 1
)

echo [SUCCESS] Signature verified
echo.

REM Create installer
if not "%SKIP_INSTALLER%"=="1" (
    echo [INFO] Creating NSIS installer...
    
    REM Create NSIS script
    call :create_nsis_script
    
    makensis "%PROJECT_ROOT%qrchat_installer.nsi"
    
    if errorlevel 1 (
        echo [ERROR] Installer creation failed
        exit /b 1
    )
    
    echo [SUCCESS] Installer created
    echo.
    
    REM Sign installer
    echo [INFO] Signing installer...
    
    "%SIGNTOOL%" sign ^
        /f "%PFX_FILE%" ^
        /p "%PFX_PASSWORD%" ^
        /tr "%TIMESTAMP_URL%" ^
        /td SHA256 ^
        /fd SHA256 ^
        /d "QRChat Installer" ^
        /du "https://qrchat.io" ^
        /v ^
        "%INSTALLER_NAME%"
    
    if errorlevel 1 (
        echo [ERROR] Failed to sign installer
        exit /b 1
    )
    
    echo [SUCCESS] Installer signed
    echo.
    
    REM Verify installer signature
    echo [INFO] Verifying installer signature...
    
    "%SIGNTOOL%" verify /pa /v "%INSTALLER_NAME%"
    
    if errorlevel 1 (
        echo [ERROR] Installer signature verification failed
        exit /b 1
    )
    
    echo [SUCCESS] Installer signature verified
    echo.
)

REM Final summary
echo ========================================================================
echo  Build Complete!
echo ========================================================================
echo.
echo [EXECUTABLE] %APP_PATH%
if not "%SKIP_INSTALLER%"=="1" (
    echo [INSTALLER]  %CD%\%INSTALLER_NAME%
)
echo.
echo [SUCCESS] Signed and ready for distribution
echo.

exit /b 0

REM ###########################################################################
REM Create NSIS installer script
REM ###########################################################################
:create_nsis_script

(
echo ; QRChat Installer Script
echo !define APP_NAME "QRChat"
echo !define APP_VERSION "%APP_VERSION%"
echo !define APP_PUBLISHER "QRChat Inc."
echo !define APP_URL "https://qrchat.io"
echo !define APP_EXE "%APP_NAME%.exe"
echo.
echo Name "${APP_NAME}"
echo OutFile "%INSTALLER_NAME%"
echo InstallDir "$PROGRAMFILES64\${APP_NAME}"
echo RequestExecutionLevel admin
echo.
echo !include "MUI2.nsh"
echo.
echo !define MUI_ICON "windows\runner\resources\app_icon.ico"
echo !define MUI_UNICON "windows\runner\resources\app_icon.ico"
echo !define MUI_WELCOMEFINISHPAGE_BITMAP "windows\runner\resources\installer_banner.bmp"
echo !define MUI_HEADERIMAGE
echo !define MUI_HEADERIMAGE_BITMAP "windows\runner\resources\installer_header.bmp"
echo !define MUI_ABORTWARNING
echo.
echo !insertmacro MUI_PAGE_WELCOME
echo !insertmacro MUI_PAGE_LICENSE "LICENSE"
echo !insertmacro MUI_PAGE_DIRECTORY
echo !insertmacro MUI_PAGE_INSTFILES
echo !insertmacro MUI_PAGE_FINISH
echo.
echo !insertmacro MUI_UNPAGE_CONFIRM
echo !insertmacro MUI_UNPAGE_INSTFILES
echo.
echo !insertmacro MUI_LANGUAGE "English"
echo.
echo Section "Install"
echo   SetOutPath "$INSTDIR"
echo   File /r "build\windows\x64\runner\Release\*.*"
echo   
echo   CreateDirectory "$SMPROGRAMS\${APP_NAME}"
echo   CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
echo   CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
echo   
echo   WriteUninstaller "$INSTDIR\Uninstall.exe"
echo   
echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "${APP_NAME}"
echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayIcon" "$INSTDIR\${APP_EXE}"
echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "${APP_PUBLISHER}"
echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "URLInfoAbout" "${APP_URL}"
echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
echo SectionEnd
echo.
echo Section "Uninstall"
echo   Delete "$INSTDIR\*.*"
echo   RMDir /r "$INSTDIR"
echo   Delete "$SMPROGRAMS\${APP_NAME}\*.*"
echo   RMDir "$SMPROGRAMS\${APP_NAME}"
echo   Delete "$DESKTOP\${APP_NAME}.lnk"
echo   DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
echo SectionEnd
) > "%PROJECT_ROOT%qrchat_installer.nsi"

exit /b 0
