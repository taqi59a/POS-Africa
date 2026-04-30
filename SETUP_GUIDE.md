# POS Africa Setup Guide

## 1. Prerequisites (Windows)

Install the following tools on your Windows build machine:

1. Flutter SDK (stable channel)
2. Visual Studio 2022 with "Desktop development with C++"
3. Inno Setup 6

Verify tools:

```powershell
flutter --version
flutter doctor -v
iscc /?
```

## 2. Prepare the Project

From project root:

```powershell
flutter config --enable-windows-desktop
flutter pub get
```

If drift table definitions were changed, regenerate code:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## 3. Build a Release Installer (Single EXE)

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\build_release_installer.ps1 -Version 1.0.0
```

This command performs:

1. `flutter pub get`
2. `flutter build windows --release`
3. Inno Setup compile via `iscc`

Final output:

`build/windows/installer/pos_africa_setup_1.0.0.exe`

This is the single EXE you can share with users.

## 4. Install and Run (End User)

1. Double-click `pos_africa_setup_1.0.0.exe`
2. Complete installation wizard
3. Launch POS Africa from Desktop or Start Menu

## 5. First Login

- Username: `admin`
- Password: `master`

Password change is required at first login.

## 6. Post-Install Validation Checklist

1. Login succeeds and password-change flow works
2. POS screen can add items and complete a sale
3. Inventory module can add/edit products
4. Customers module can create a customer
5. Reports and Audit pages load without crash
6. Manual backup export works in Settings
7. Backup restore stages successfully and is applied after app restart
