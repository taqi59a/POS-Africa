<#
.SYNOPSIS
    Builds a portable (no-install) ZIP of POS Africa for Windows.

.PARAMETER Version
    Version string to embed in the folder / ZIP name (e.g. 1.2.0)

.EXAMPLE
    .\build_portable.ps1 -Version "1.2.0"
#>
param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ── Helpers ──────────────────────────────────────────────────────────────────

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name. Please install it and add it to PATH."
    }
}

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host "==> $Msg" -ForegroundColor Cyan
}

# ── Validate environment ──────────────────────────────────────────────────────

Write-Step "Checking required tools"
Require-Command flutter
Require-Command dart

# ── Paths ─────────────────────────────────────────────────────────────────────

$scriptDir  = Split-Path -Parent $PSCommandPath
$repoRoot   = Resolve-Path (Join-Path $scriptDir "..\..")
$releaseDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
$portRoot   = Join-Path $repoRoot "build\windows\portable"
$portDir    = Join-Path $portRoot "POS_Africa_$Version"
$zipPath    = Join-Path $portRoot "POS_Africa_${Version}_Portable.zip"

Write-Host "Repo root : $repoRoot"
Write-Host "Output ZIP: $zipPath"

Set-Location $repoRoot

# ── Flutter build ─────────────────────────────────────────────────────────────

Write-Step "Getting pub dependencies"
flutter config --enable-windows-desktop
flutter pub get

Write-Step "Running build_runner (Drift code generation)"
dart run build_runner build --delete-conflicting-outputs

Write-Step "Building Flutter Windows release ($Version)"
flutter build windows `
    --release `
    --build-name $Version `
    --build-number ([int](Get-Date -Format "yyyyMMdd"))

# ── Verify output ─────────────────────────────────────────────────────────────

$exePath = Join-Path $releaseDir "pos_africa.exe"
if (-not (Test-Path $exePath)) {
    throw "pos_africa.exe not found in release output: $releaseDir"
}

# ── Assemble portable folder ──────────────────────────────────────────────────

Write-Step "Assembling portable folder"

if (Test-Path $portDir) { Remove-Item $portDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $portDir | Out-Null

Copy-Item -Path "$releaseDir\*" -Destination $portDir -Recurse -Force

# ── Portable README ───────────────────────────────────────────────────────────

$readmeContent = @"
POS Africa $Version  –  Portable Edition
==========================================
No installation required. Just run pos_africa.exe.

SYSTEM REQUIREMENTS
-------------------
  • Windows 10 (build 1809 / October 2018 Update) or Windows 11
  • 64-bit processor
  • 50 MB disk space for the application
  • 500 MB disk space recommended for data and backups

  If you see a "MSVCP140.dll not found" error, install the free
  Visual C++ runtime from Microsoft:
  https://aka.ms/vs/17/release/vc_redist.x64.exe

FIRST RUN
---------
  1. Double-click pos_africa.exe
  2. Log in with:   Username: admin   Password: master
  3. You will be asked to change the password immediately.

DATA STORAGE
------------
  Database and backups are stored under:
    %USERPROFILE%\Documents\CongoPOS\
  Main database file:
    %USERPROFILE%\Documents\CongoPOS\db.sqlite

  This folder is SEPARATE from the application folder, so upgrading
  or moving this portable folder will NOT affect your data.

UPDATING
--------
  Replace the contents of this folder with the newer version.
  Your %USERPROFILE%\Documents\CongoPOS\ data is untouched.

SUPPORT
-------
  https://github.com/taqi59a/POS-Africa/issues
"@

$readmeContent | Set-Content -Path (Join-Path $portDir "README.txt") -Encoding UTF8

# ── Compress to ZIP ───────────────────────────────────────────────────────────

Write-Step "Compressing to ZIP"

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path $portDir -DestinationPath $zipPath -CompressionLevel Optimal

$sizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
Write-Host ""
Write-Host "Done! Portable ZIP: $zipPath  ($sizeMB MB)" -ForegroundColor Green
Write-Host "Contained EXE     : $portDir\pos_africa.exe"
