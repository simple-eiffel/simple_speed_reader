; ============================================================================
;  Simple Speed Reader - Inno Setup script
;
;  Ships: the finalized GUI (statically linked Eiffel, only Windows system
;  DLLs), the headless AI worker it spawns for quiz generation (same engine,
;  own exe), cairo.dll (the 2D face - no Vision2, no GTK), the program icon,
;  a demo text that exercises the scholarly timing (Hebrew, Greek,
;  transliterations, Strong's refs), and the user guide.
;
;  Ollama is OPTIONAL here: the reader is fully functional without it; only
;  the comprehension-quiz feature needs a local model.
;
;  The app keeps its profile (speed_reader.cfg), reading ledger
;  (speed_reader.db) and log beside the exe - a per-user install, so {app}
;  is writable and everything stays in one place.
;
;  Build:  "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" simple_speed_reader.iss
; ============================================================================

#define AppName        "Simple Speed Reader"
#define AppVersion     "0.9.0"
#define AppPublisher   "Larry Rix"
#define AppExeName     "simple_speed_reader.exe"

[Setup]
AppId={{C226CF56-B82C-4593-A61F-A6EAAFB320C3}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=.\output
OutputBaseFilename=SimpleSpeedReader-{#AppVersion}-Setup
SetupIconFile=..\app\resources\speed_reader.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\speed_reader.ico

; Per-user install: no UAC prompt; the app writes only beside itself.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; The Eiffel binary is 64-bit.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "..\EIFGENs\speed_reader\F_code\simple_speed_reader.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\EIFGENs\speed_reader_worker\F_code\simple_speed_reader.exe"; DestDir: "{app}"; DestName: "speed_reader_worker.exe"; Flags: ignoreversion
Source: "..\EIFGENs\speed_reader\F_code\cairo.dll"; DestDir: "{app}"; Flags: ignoreversion
; Poppler's pdftotext (GPL, bundled by simple_pdf) - the PDF text layer's door.
Source: "D:\prod\simple_pdf\bin\pdftotext.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\app\resources\speed_reader.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\demo\sample_text.md"; DestDir: "{app}\demo"; Flags: ignoreversion
Source: "..\docs\USER_GUIDE.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}";           Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\speed_reader.ico"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}";     Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\speed_reader.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; The app's own working droppings - never the user's texts.
Type: files; Name: "{app}\speed_reader.log"
Type: files; Name: "{app}\quiz_in.txt"
Type: files; Name: "{app}\quiz_out.json"
Type: files; Name: "{app}\quiz_out.json.tmp"

[Code]

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  CfgPath, DbPath: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    CfgPath := ExpandConstant('{app}\speed_reader.cfg');
    DbPath  := ExpandConstant('{app}\speed_reader.db');

    { Delete the profile and the READING LEDGER only after an explicit yes
      from a real dialog. UninstallSilent must be checked first: under
      /VERYSILENT with /SUPPRESSMSGBOXES a MsgBox returns its DEFAULT
      answer - IDYES for MB_YESNO - so an unguarded prompt silently answers
      itself and destroys the user's history during any scripted uninstall
      (the simple_ocr_capture lesson, learned the hard way). }
    if (FileExists(CfgPath) or FileExists(DbPath)) and (not UninstallSilent) then
      if MsgBox('Remove your reading profile and history as well?' + #13#10#13#10 +
                'This deletes your speed settings and the ledger of every run' + #13#10 +
                '(speeds achieved, rewinds, quiz scores).' + #13#10#13#10 +
                'Choose No to keep them for a future reinstall.',
                mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES then
      begin
        DeleteFile(CfgPath);
        DeleteFile(DbPath);
      end;
  end;
end;
