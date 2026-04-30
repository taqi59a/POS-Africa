#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  build_source_package.sh
#
#  Run this in GitHub Codespace (or any Linux machine) to create a ZIP
#  that contains everything needed to build the Windows EXE on any
#  Windows machine with ONE double-click.
#
#  Usage:
#    chmod +x scripts/build_source_package.sh
#    bash scripts/build_source_package.sh [version]
#
#  Output:
#    build/POS_Africa_<version>_WindowsBuild.zip
# ─────────────────────────────────────────────────────────────────────────────

set -e

VERSION="${1:-1.0.0}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$REPO_ROOT/build"
ZIP_NAME="POS_Africa_${VERSION}_WindowsBuild.zip"
ZIP_PATH="$OUT_DIR/$ZIP_NAME"
TMP_DIR="$(mktemp -d)"
PKG_DIR="$TMP_DIR/POS_Africa_${VERSION}"

echo ""
echo "==> Packaging POS Africa $VERSION for Windows build"
echo "    From: $REPO_ROOT"
echo "    To:   $ZIP_PATH"
echo ""

mkdir -p "$PKG_DIR" "$OUT_DIR"

# ── Copy source files ─────────────────────────────────────────────────────────
echo "--> Copying source files..."
rsync -a \
  --exclude='.git' \
  --exclude='.github' \
  --exclude='build' \
  --exclude='.dart_tool' \
  --exclude='.idea' \
  --exclude='.vscode' \
  --exclude='*.log' \
  "$REPO_ROOT/" "$PKG_DIR/"

# ── Download Flutter pub cache into package (optional speed-up) ───────────────
# This is skipped intentionally — flutter pub get is fast enough on Windows
# and pre-bundling the pub cache (400 MB) unnecessarily bloats the ZIP.

# ── Write the one-click BUILD.bat ─────────────────────────────────────────────
echo "--> Writing BUILD.bat..."
cat > "$PKG_DIR/BUILD.bat" << 'BATEOF'
@echo off
title POS Africa – Windows Builder
color 0A
setlocal EnableDelayedExpansion

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║           POS Africa – Windows EXE Builder               ║
echo  ║  This will build the installer EXE on this machine.      ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

:: ── Check Flutter ────────────────────────────────────────────────────────────
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo  ERROR: Flutter is not installed or not in PATH.
    echo.
    echo  Install steps:
    echo  1. Go to: https://flutter.dev/docs/get-started/install/windows
    echo  2. Extract Flutter to C:\flutter
    echo  3. Add C:\flutter\bin to your system PATH
    echo  4. Re-run this BUILD.bat
    echo.
    pause
    exit /b 1
)

:: ── Check Visual Studio build tools ──────────────────────────────────────────
where cl >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    color 0E
    echo  WARNING: MSVC compiler (cl.exe) not found in PATH.
    echo  Flutter will use it automatically if Visual Studio 2022 is installed.
    echo  If build fails, install Visual Studio 2022 Community (free):
    echo  https://visualstudio.microsoft.com/vs/community/
    echo  (select: Desktop development with C++)
    echo.
)

echo  Flutter found. Starting build...
echo.

:: ── Navigate to script directory ─────────────────────────────────────────────
cd /d "%~dp0"

:: ── Enable Windows desktop ────────────────────────────────────────────────────
echo [1/5] Enabling Windows desktop support...
flutter config --enable-windows-desktop

:: ── Get dependencies ─────────────────────────────────────────────────────────
echo [2/5] Downloading dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 ( echo FAILED: pub get && pause && exit /b 1 )

:: ── Code generation (Drift ORM) ───────────────────────────────────────────────
echo [3/5] Running code generator...
dart run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 ( echo FAILED: build_runner && pause && exit /b 1 )

:: ── Flutter build ─────────────────────────────────────────────────────────────
echo [4/5] Building Windows release...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 ( echo FAILED: flutter build windows && pause && exit /b 1 )

:: ── Check result ──────────────────────────────────────────────────────────────
set EXE=build\windows\x64\runner\Release\pos_africa.exe
if not exist "%EXE%" (
    color 0C
    echo  ERROR: EXE not found at %EXE%
    pause
    exit /b 1
)

echo [5/5] Build complete!
echo.
color 0A
echo  ══════════════════════════════════════════════
echo  SUCCESS! Your app EXE is ready:
echo  %~dp0%EXE%
echo.
echo  To create the full installer:
echo    scripts\windows\build_release_installer.ps1
echo  (requires Inno Setup: https://jrsoftware.org/isdl.php)
echo  ══════════════════════════════════════════════
echo.

:: ── Open the output folder ────────────────────────────────────────────────────
set OUT_FOLDER=%~dp0build\windows\x64\runner\Release
echo  Opening output folder...
explorer "%OUT_FOLDER%"

pause
BATEOF

# ── Write a simple README ─────────────────────────────────────────────────────
echo "--> Writing README.txt..."
cat > "$PKG_DIR/WINDOWS_BUILD_INSTRUCTIONS.txt" << EOF
POS Africa $VERSION – Windows Build Package
============================================

HOW TO BUILD THE WINDOWS EXE
-----------------------------
1. Copy this entire folder to your Windows machine
   (USB stick, shared drive, or download from GitHub)

2. Install Flutter on Windows (one-time setup):
   https://flutter.dev/docs/get-started/install/windows

3. Install Visual Studio 2022 Community (free, one-time setup):
   https://visualstudio.microsoft.com/vs/community/
   — Select workload: "Desktop development with C++"

4. Double-click BUILD.bat in this folder.

5. When done, your EXE is at:
   build\\windows\\x64\\runner\\Release\\pos_africa.exe

FOR A PROPER INSTALLER EXE (optional):
---------------------------------------
1. Install Inno Setup: https://jrsoftware.org/isdl.php
2. Run in PowerShell:
   .\\scripts\\windows\\build_release_installer.ps1 -Version "$VERSION"
3. Installer EXE will appear at:
   build\\windows\\installer\\pos_africa_setup_$VERSION.exe

FIRST LOGIN
-----------
Username: admin
Password: admin123
(You will be asked to change the password on first login)

DATA STORAGE
------------
The database is stored in:
  %APPDATA%\\POS Africa\\
EOF

# ── Create ZIP ────────────────────────────────────────────────────────────────
echo "--> Creating ZIP..."
cd "$TMP_DIR"
zip -r "$ZIP_PATH" "POS_Africa_${VERSION}" -x "*.DS_Store" "*.git*" > /dev/null

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$TMP_DIR"

SIZE=$(du -sh "$ZIP_PATH" | cut -f1)
echo ""
echo "==> Done!"
echo "    ZIP: $ZIP_PATH  ($SIZE)"
echo ""
echo "    Download from VS Code: Explorer panel -> build/ -> ${ZIP_NAME}"
echo "    Then copy to Windows and double-click BUILD.bat"
