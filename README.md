# POS Africa

POS Africa is a Flutter desktop Point-of-Sale application with inventory,
billing, customers, reports, expenses, audit logs, and settings modules.

## Development Setup

1. Install Flutter SDK.
2. Enable Windows desktop support:

	```bash
	flutter config --enable-windows-desktop
	```

3. Install dependencies:

	```bash
	flutter pub get
	```

4. Run locally on Windows:

	```bash
	flutter run -d windows
	```

## Build Windows Release

Create optimized binaries:

```bash
flutter build windows --release
```

Release output folder:

`build/windows/x64/runner/Release`

## Single EXE Installer (Recommended)

Flutter Windows apps require runtime files next to the main EXE. To keep user
distribution simple, this repo provides a single installer EXE using Inno Setup.

### Prerequisites

1. Inno Setup installed on Windows.
2. `iscc` available in `PATH`.

### Generate Installer

From PowerShell on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\build_release_installer.ps1 -Version 1.0.0
```

Installer output:

`build/windows/installer/pos_africa_setup_1.0.0.exe`

Users can install from this single EXE.

## Automated EXE Production (GitHub Actions)

This repository includes a Windows CI workflow at:

`.github/workflows/windows-installer.yml`

How to use:

1. Manual run: open Actions and run `Build Windows Installer` with a version input.
2. Tag release: push a tag like `v1.0.0` to automatically build and attach EXE to the GitHub release.

Workflow outputs:

1. Artifact: `windows-installer-<version>`
2. On tag builds, release asset: `pos_africa_setup_<version>.exe`

## Default First Login

- Username: `admin`
- Password: `master`

The app forces a password change on first login.
