@echo off
setlocal

set VERSION=%1
if "%VERSION%"=="" set VERSION=1.0.0

echo Building POS Africa installer version %VERSION%...
powershell -ExecutionPolicy Bypass -File "%~dp0build_release_installer.ps1" -Version %VERSION%
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)

echo Installer created successfully.
echo Output: build\windows\installer\pos_africa_setup_%VERSION%.exe
exit /b 0
