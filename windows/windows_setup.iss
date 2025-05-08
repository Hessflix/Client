[Setup]
AppId={{D573EDD5-117A-47AD-88AC-62C8EBD11DC7}
AppName="Hessflix"
AppVersion={%HESSFLIX_VERSION|latest}
AppPublisher="Hessflix"
AppPublisherURL="https://github.com/DonutWare/Hessflix"
AppSupportURL="https://github.com/DonutWare/Hessflix"
AppUpdatesURL="https://github.com/DonutWare/Hessflix"
DefaultDirName={localappdata}\Programs\Hessflix
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputBaseFilename=hessflix_setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

SetupLogging=yes
UninstallLogging=yes
UninstallDisplayName="Hessflix"
UninstallDisplayIcon={app}\hessflix.exe
SetupIconFile="D:\a\Hessflix\Hessflix\icons\production\hessflix_icon.ico"
LicenseFile="D:\a\Hessflix\Hessflix\LICENSE"
WizardImageFile=D:\a\Hessflix\Hessflix\assets\windows-installer\hessflix-installer-100.bmp,D:\a\Hessflix\Hessflix\assets\windows-installer\hessflix-installer-125.bmp,D:\a\Hessflix\Hessflix\assets\windows-installer\hessflix-installer-150.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "D:\a\Hessflix\Hessflix\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Hessflix"; Filename: "{app}\hessflix.exe"
Name: "{autodesktop}\Hessflix"; Filename: "{app}\hessflix.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\hessflix.exe"; Description: "{cm:LaunchProgram,Hessflix}"; Flags: nowait postinstall skipifsilent

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  case CurUninstallStep of
    usUninstall:
      begin
        if MsgBox('Would you like to delete the application''s data? This action cannot be undone. Synced files will remain unaffected.', mbConfirmation, MB_YESNO) = IDYES then
        begin
            if DelTree(ExpandConstant('{localappdata}\DonutWare'), True, True, True) = False then
            begin
                Log(ExpandConstant('{localappdata}\DonutWare could not be deleted. Skipping...'));
            end;
        end;
      end;
  end;
end;