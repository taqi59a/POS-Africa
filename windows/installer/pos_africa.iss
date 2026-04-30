; ─────────────────────────────────────────────────────────────
;  POS Africa  –  Inno Setup 6 Installer Script
;  Targets: Windows 10 / 11 x64  (Flutter minimum requirement)
;  Produces: pos_africa_setup_<version>.exe
; ─────────────────────────────────────────────────────────────
#define MyAppName      "POS Africa"
#define MyAppVersion   "1.0.0"
#define MyAppPublisher "POS Africa Ltd"
#define MyAppURL       "https://github.com/taqi59a/POS-Africa"
#define MyAppExeName   "pos_africa.exe"
#define MyAppDataDir   "{userappdata}\\POS Africa"
#define BuildDir       "..\\..\\build\\windows\\x64\\runner\\Release"

; ── Version injected at build time with /DMyAppVersion=x.y.z ─
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

[Setup]
; Unique GUID – do NOT change: drives upgrade detection
AppId={{C6F1AF89-E39D-4A4D-BB37-1E45F680A76F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases

; Require Windows 10 (1809+) x64 – Flutter desktop requirement
MinVersion=10.0.17763
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

DefaultDirName={autopf}\\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DirExistsWarning=no

; Installer appearance
WizardStyle=modern
WizardSizePercent=110
SetupIconFile=..\\runner\\resources\\app_icon.ico
UninstallDisplayIcon={app}\\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

; Output
OutputDir=..\\..\\build\\windows\\installer
OutputBaseFilename=pos_africa_setup_{#MyAppVersion}

; Compression (best ratio, suitable for distribution)
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

; Signing (no-op unless SignTool is configured on the build machine)
; SignTool=signtool

; Restart not needed
RestartIfNeededByRun=no
AlwaysShowComponentsList=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french";  MessagesFile: "compiler:Languages\\French.isl"

[Tasks]
Name: "desktopicon";  Description: "Create a &desktop shortcut";   GroupDescription: "Additional shortcuts:"; Flags: unchecked
Name: "quicklaunch"; Description: "Pin to &taskbar after launch";   GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Dirs]
; Ensure the user-writable data dir exists on install (stores the SQLite DB)
Name: "{userappdata}\\POS Africa"; Permissions: users-full

[Files]
; ── Main application bundle (all DLLs, data/, flutter_assets/ etc.) ──
Source: "{#BuildDir}\\*";       DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

; ── Visual C++ 2022 runtime (x64) – bundled so app works offline ──
; Download vc_redist.x64.exe from Microsoft and place it next to the .iss
; before running iscc. GitHub Actions step does this automatically.
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: NeedsVCRedist

[Icons]
Name: "{autoprograms}\\{#MyAppName}";        Filename: "{app}\\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\\{#MyAppName}";         Filename: "{app}\\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{autoprograms}\\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

[Run]
; Install VC++ runtime silently if needed (runs before app launch)
Filename: "{tmp}\\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; \
  StatusMsg: "Installing Visual C++ Runtime..."; \
  Check: NeedsVCRedist; Flags: runhidden waituntilterminated

; Launch app after install
Filename: "{app}\\{#MyAppExeName}"; Description: "Launch {#MyAppName} now"; \
  Flags: nowait postinstall skipifsilent shellexec

[UninstallRun]
; Nothing extra – the uninstaller removes {app} contents automatically

[UninstallDelete]
; Remove user data directory on uninstall (prompt is shown by code below)
Type: filesandordirs; Name: "{userappdata}\\POS Africa"

[Registry]
; App Paths so Windows "Run" dialog finds it
Root: HKCU; Subkey: "Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\{#MyAppExeName}"; \
  ValueType: string; ValueName: ""; ValueData: "{app}\\{#MyAppExeName}"; Flags: uninsdeletekey

[Code]
// ── Detect whether the Visual C++ 2022 x64 runtime is installed ──────────────
function NeedsVCRedist: Boolean;
var
  installed: Boolean;
  version: String;
begin
  // Check for VC++ 2022 / 2019 runtime (14.x)
  installed := RegQueryStringValue(HKLM,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'Version', version);
  if not installed then
    installed := RegQueryStringValue(HKLM,
      'SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
      'Version', version);
  Result := not installed;
end;

// ── Offer to keep or remove user data on uninstall ───────────────────────────
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  msg, dataDir: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    dataDir := ExpandConstant('{userappdata}\POS Africa');
    if DirExists(dataDir) then
    begin
      msg := 'Do you want to remove all POS Africa data (database, backups)?' + #13#10 +
             'Location: ' + dataDir + #13#10#13#10 +
             'Click YES to delete everything, NO to keep your data.';
      if MsgBox(msg, mbConfirmation, MB_YESNO) = IDYES then
        DelTree(dataDir, True, True, True);
    end;
  end;
end;
