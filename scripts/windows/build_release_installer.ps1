<#
.SYNOPSIS
    Full release build: Flutter Windows release + Inno Setup installer EXE.

.PARAMETER Version
    Semantic version string (e.g. 1.2.0).  Injected into the EXE and installer.

.PARAMETER SkipPubGet
    Skip "flutter pub get" (useful when dependencies are already up to date).

.EXAMPLE
    .\build_release_installer.ps1 -Version "1.2.0"
#>
param(
    [string]$Version    = "1.0.0",
    [switch]$SkipPubGet = $false
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name. Please install it and add it to PATH."
    }
}

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host "==> $Msg" -ForegroundColor Cyan
}

# ── Validate tools ────────────────────────────────────────────────────────────

Write-Step "Checking required tools"
Require-Command flutter
Require-Command dart

$iscc = Get-Command iscc -ErrorAction SilentlyContinue
if (-not $iscc) {
    throw "Inno Setup compiler (iscc) not found. Install from https://jrsoftware.org/isdl.php"
}

# ── Paths ─────────────────────────────────────────────────────────────────────

$scriptDir  = Split-Path -Parent $PSCommandPath
$repoRoot   = Resolve-Path (Join-Path $scriptDir "..\..")
$issScript  = Join-Path $repoRoot "windows\installer\pos_africa.iss"
$releaseDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
$outputDir  = Join-Path $repoRoot "build\windows\installer"

Write-Host "Repo root    : $repoRoot"
Write-Host "Iss script   : $issScript"
Write-Host "Output dir   : $outputDir"
Write-Host "Version      : $Version"
Set-Location $repoRoot

# ── Dependencies ──────────────────────────────────────────────────────────────

if (-not $SkipPubGet) {
    Write-Step "Getting pub dependencies"
    flutter config --enable-windows-desktop
    flutter pub get
}

Write-Step "Running build_runner (Drift code generation)"
dart run build_runner build --delete-conflicting-outputs

# ── Flutter release build ─────────────────────────────────────────────────────

Write-Step "Building Flutter Windows release ($Version)"
flutter build windows `
    --release `
    --build-name $Version `
    --build-number ([int](Get-Date -Format "yyyyMMdd"))

# ── Verify EXE ────────────────────────────────────────────────────────────────

$exePath = Join-Path $releaseDir "pos_africa.exe"
if (-not (Test-Path $exePath)) {
    throw "pos_africa.exe not found after build: $exePath"
}
$sizeMB = [math]::Round((Get-Item $exePath).Length / 1MB, 2)
Write-Host "pos_africa.exe: $sizeMB MB"

# ── Download VC++ redist if not already present ───────────────────────────────

$vcRedist = Join-Path $repoRoot "windows\installer\vc_redist.x64.exe"
if (-not (Test-Path $vcRedist)) {
    Write-Step "Downloading Visual C++ 2022 redistributable"
    Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" `
                      -OutFile $vcRedist -UseBasicParsing
    Write-Host "Downloaded vc_redist.x64.exe"
}

# ── Inno Setup compile ────────────────────────────────────────────────────────

Write-Step "Compiling installer with Inno Setup"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
& iscc "/DMyAppVersion=$Version" $issScript

if ($LASTEXITCODE -ne 0) {
    throw "iscc exited with code $LASTEXITCODE"
}

# ── Report ────────────────────────────────────────────────────────────────────

$setupExe = Get-ChildItem -Path $outputDir -Filter "pos_africa_setup_*.exe" `
            | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($setupExe) {
    $setupMB = [math]::Round($setupExe.Length / 1MB, 2)
    Write-Host ""
    Write-Host "SUCCESS  Installer: $($setupExe.FullName)  ($setupMB MB)" -ForegroundColor Green
} else {
    Write-Warning "Build succeeded but no installer EXE found in $outputDir"
}

