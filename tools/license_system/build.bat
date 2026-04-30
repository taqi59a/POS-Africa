@echo off
setlocal enabledelayedexpansion
title License System Builder
color 0B

echo.
echo  ============================================================
echo   License System Builder  --  POS Africa
echo  ============================================================
echo.

:: ── Prerequisites ──────────────────────────────────────────────────────────
echo [1/5] Installing build tools...
pip install pyinstaller pyarmor --quiet --upgrade
if errorlevel 1 (
    echo ERROR: pip failed. Make sure Python is on your PATH.
    pause & exit /b 1
)

:: ── Optional PyArmor obfuscation step ──────────────────────────────────────
:: Uncomment the block below to obfuscate before building.
:: Obfuscated output goes to dist\pyarmor_runtime_XXXXXX\ — build from there.
::
:: echo [2/5] Obfuscating with PyArmor...
:: pyarmor gen ^
::   shared_crypto.py hardware_id.py license_store.py main.py keygen.py
:: if errorlevel 1 ( echo PyArmor failed & pause & exit /b 1 )
:: echo Obfuscation done. Build from dist\pyarmor_runtime_*\ if needed.
::
echo [2/5] Skipping obfuscation (uncomment in build.bat to enable)

:: ── Clean previous build artefacts ─────────────────────────────────────────
echo [3/5] Cleaning old build folders...
if exist build  rmdir /s /q build
if exist dist   rmdir /s /q dist

:: ── Build main.exe  (protected application) ────────────────────────────────
echo [4/5] Building main application...
pyinstaller ^
  --onefile ^
  --windowed ^
  --clean ^
  --name "MyApp" ^
  main.py
if errorlevel 1 ( echo BUILD FAILED for main.py & pause & exit /b 1 )

:: ── Build KeyGen_ADMIN.exe  (admin-only keygen) ────────────────────────────
echo [5/5] Building keygen tool...
pyinstaller ^
  --onefile ^
  --windowed ^
  --clean ^
  --name "KeyGen_ADMIN" ^
  keygen.py
if errorlevel 1 ( echo BUILD FAILED for keygen.py & pause & exit /b 1 )

:: ── Done ────────────────────────────────────────────────────────────────────
echo.
echo  ============================================================
echo   BUILD COMPLETE
echo.
echo   dist\MyApp.exe        -- distribute to customers
echo   dist\KeyGen_ADMIN.exe -- keep private (admin only)
echo  ============================================================
echo.
echo  Remember:
echo    1. Customise APP_NAME / VENDOR_NAME in main.py before distributing.
echo    2. Change the _SA _SB _SC _SD salt segments in shared_crypto.py.
echo    3. Enable PyArmor obfuscation for production builds.
echo.
pause
