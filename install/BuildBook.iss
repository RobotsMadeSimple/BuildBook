; Windows installer for BuildBook (Inno Setup 6).
;
; Built by GitHub Actions for every release (see .github/workflows/release.yml):
;   iscc /DAppVersion=1.2 install\BuildBook.iss      -> dist\BuildBook-Setup-1.2.exe
;
; Installs for the current user only (no administrator rights needed) into Fusion's add-ins
; folder. Fusion loads it on its next start. Running a newer installer updates it; Windows'
; "Installed apps" uninstalls it. Each user's own BuildBook data (logs, thumbnails, settings in
; %APPDATA%\RobotsMadeSimple) is left alone.

#ifndef AppVersion
  #define AppVersion "dev"
#endif

[Setup]
AppId={{4E2638A6-9878-4C2C-B6E7-52A4C75D7BE2}
AppName=BuildBook for Fusion
AppVersion={#AppVersion}
AppPublisher=Robots Made Simple
AppPublisherURL=https://github.com/RobotsMadeSimple/BuildBook
AppSupportURL=https://github.com/RobotsMadeSimple/BuildBook/blob/main/INSTALL.md
DefaultDirName={userappdata}\Autodesk\Autodesk Fusion 360\API\AddIns
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=BuildBook-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=BuildBook for Fusion
; (the add-ins folder is Fusion's: never removed, only BuildBook's folder inside it)
UninstallFilesDir={userappdata}\RobotsMadeSimple\BuildBook\uninstall
LicenseFile=..\LICENSE

[Files]
Source: "..\BuildBook\*"; DestDir: "{app}\BuildBook"; \
  Excludes: "logs\*,cache\*,thumbs\*,tests\*,tools\*,__pycache__,*.pyc"; Flags: recursesubdirs createallsubdirs ignoreversion

[UninstallDelete]
; (files the add-in made while running: Python's caches)
Type: filesandordirs; Name: "{app}\BuildBook\__pycache__"
Type: filesandordirs; Name: "{app}\BuildBook\commands\__pycache__"
Type: filesandordirs; Name: "{app}\BuildBook\lib\__pycache__"

[Messages]
FinishedLabel=BuildBook is installed.%n%nRestart Fusion (close it completely and open it again). It starts on its own: its button is in the Utilities tab, under Add-Ins.

[Code]
function IsLink(const Path: String): Boolean;
var
  Rec: TFindRec;
begin
  Result := False;
  if FindFirst(Path, Rec) then
  begin
    Result := (Rec.Attributes and FILE_ATTRIBUTE_REPARSE_POINT) <> 0;
    FindClose(Rec);
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
{ BuildBook installed with the Git install script is a link to the user's copy of the
  repository: remove only the link (never write into their repository). A plain folder is
  updated in place. }
var
  Path: String;
  Code: Integer;
begin
  Result := '';
  Path := ExpandConstant('{app}\BuildBook');
  if DirExists(Path) and IsLink(Path) then
    Exec(ExpandConstant('{cmd}'), '/c rmdir "' + Path + '"', '', SW_HIDE, ewWaitUntilTerminated, Code);
end;

function InitializeSetup(): Boolean;
var
  Code: Integer;
begin
  Result := True;
  { Fusion running: it keeps using the old version until it's restarted (installing is fine). }
  if Exec(ExpandConstant('{cmd}'), '/c tasklist /FI "IMAGENAME eq Fusion360.exe" | find /I "Fusion360.exe" >nul',
          '', SW_HIDE, ewWaitUntilTerminated, Code) and (Code = 0) then
    Result := MsgBox('Fusion is open. You can install now, but BuildBook only updates after Fusion is ' +
                     'closed and opened again.' + #13#10#13#10 + 'Continue?', mbConfirmation, MB_YESNO) = IDYES;
end;
