; Script de Inno Setup para Label Printer
; Centro Diagnóstico v5

#define MyAppName "Label Printer - Centro Diagnóstico"
#define MyAppVersion "5.0"
#define MyAppPublisher "Centro Diagnóstico"
#define MyAppExeName "LabelPrinter.exe"

[Setup]
AppId={{9B8C0D1E-5F6A-7B8C-9D0E-1F2A3B4C5D6E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName=C:\Centro Diagnostico\LabelPrinter
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=Setup_LabelPrinter
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checked
Name: "startup"; Description: "Iniciar automáticamente con Windows"; GroupDescription: "Opciones:"; Flags: unchecked

[Files]
Source: "dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\config.json"; DestDir: "{app}"; Flags: ignoreversion onlyifdoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Configuración"; Filename: "notepad.exe"; Parameters: """{app}\config.json"""
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Label Printer"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "LabelPrinter"; ValueData: """{app}\{#MyAppExeName}"""; Flags: uninsdeletevalue; Tasks: startup

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  ConfigPage: TInputQueryWizardPage;

procedure InitializeWizard;
begin
  ConfigPage := CreateInputQueryPage(wpSelectDir,
    'Configuración del Label Printer', 
    'Ingrese la configuración básica',
    'Por favor ingrese la URL del servidor.');
    
  ConfigPage.Add('URL del Servidor:', False);
  ConfigPage.Values[0] := 'http://192.9.135.84:5000/api';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigFile: string;
  ConfigContent: TStringList;
begin
  if CurStep = ssPostInstall then
  begin
    ConfigFile := ExpandConstant('{app}\config.json');
    
    if FileExists(ConfigFile) then
    begin
      ConfigContent := TStringList.Create;
      try
        ConfigContent.LoadFromFile(ConfigFile);
        
        ConfigContent.Text := StringReplace(ConfigContent.Text, 
          '"server_url": "http://192.9.135.84:5000/api"',
          '"server_url": "' + ConfigPage.Values[0] + '"',
          [rfReplaceAll, rfIgnoreCase]);
          
        ConfigContent.SaveToFile(ConfigFile);
      finally
        ConfigContent.Free;
      end;
    end;
  end;
end;

[UninstallDelete]
Type: files; Name: "{app}\temp_label_*.png"
Type: files; Name: "{app}\*.log"
