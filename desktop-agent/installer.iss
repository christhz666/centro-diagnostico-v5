; Script de Inno Setup para Desktop Agent
; Centro Diagnóstico v5

#define MyAppName "Centro Diagnóstico Agent"
#define MyAppVersion "5.0"
#define MyAppPublisher "Centro Diagnóstico"
#define MyAppExeName "CentroDiagnosticoAgent.exe"
#define MyAppAssocName MyAppName + " File"
#define MyAppAssocExt ".cda"
#define MyAppAssocKey StringChange(MyAppAssocName, " ", "") + MyAppAssocExt

[Setup]
; Información básica de la app
AppId={{8A7B9C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName=C:\Centro Diagnostico\Agent
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=Setup_CentroDiagAgent
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; Privilegios
PrivilegesRequired=admin

; Iconos y UI
SetupIconFile=
WizardImageFile=
WizardSmallImageFile=

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startup"; Description: "Iniciar automáticamente con Windows"; GroupDescription: "Opciones:"; Flags: checked

[Files]
; Ejecutable principal
Source: "dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; Archivo de configuración de ejemplo
Source: "config.example.json"; DestDir: "{app}"; Flags: ignoreversion onlyifdoesntexist; DestName: "config.json"
; README
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme

[Icons]
; Acceso directo en menú inicio
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Configuración"; Filename: "notepad.exe"; Parameters: """{app}\config.json"""
Name: "{group}\Ver Logs"; Filename: "notepad.exe"; Parameters: """{app}\agent.log"""
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

; Acceso directo en escritorio
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Agregar al inicio de Windows
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "CentroDiagnosticoAgent"; ValueData: """{app}\{#MyAppExeName}"""; Flags: uninsdeletevalue; Tasks: startup

[Run]
; Ejecutar el agente después de instalar
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  ConfigPage: TInputQueryWizardPage;

procedure InitializeWizard;
begin
  // Crear página de configuración personalizada
  ConfigPage := CreateInputQueryPage(wpSelectDir,
    'Configuración del Agente', 
    'Ingrese la configuración básica',
    'Por favor ingrese la URL del servidor y el nombre de esta estación.');
    
  // Campo para URL del servidor
  ConfigPage.Add('URL del Servidor:', False);
  ConfigPage.Values[0] := 'http://192.9.135.84:5000/api';
  
  // Campo para nombre de estación
  ConfigPage.Add('Nombre de Estación:', False);
  ConfigPage.Values[1] := 'PC-LABORATORIO';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigFile: string;
  ConfigContent: TStringList;
begin
  if CurStep = ssPostInstall then
  begin
    // Actualizar el archivo config.json con los valores ingresados
    ConfigFile := ExpandConstant('{app}\config.json');
    
    if FileExists(ConfigFile) then
    begin
      ConfigContent := TStringList.Create;
      try
        ConfigContent.LoadFromFile(ConfigFile);
        
        // Reemplazar valores en el JSON
        ConfigContent.Text := StringReplace(ConfigContent.Text, 
          '"server_url": "http://192.9.135.84:5000/api"',
          '"server_url": "' + ConfigPage.Values[0] + '"',
          [rfReplaceAll, rfIgnoreCase]);
          
        ConfigContent.Text := StringReplace(ConfigContent.Text,
          '"station_name": "PC-LABORATORIO"',
          '"station_name": "' + ConfigPage.Values[1] + '"',
          [rfReplaceAll, rfIgnoreCase]);
          
        ConfigContent.SaveToFile(ConfigFile);
      finally
        ConfigContent.Free;
      end;
    end;
  end;
end;

[UninstallDelete]
; Limpiar archivos generados
Type: files; Name: "{app}\agent.log"
Type: files; Name: "{app}\ports_cache.json"
Type: filesandordirs; Name: "{app}\__pycache__"
