@echo off
REM Build script para Desktop Agent
REM Genera un ejecutable standalone usando PyInstaller

echo ========================================
echo Centro Diagnostico v5 - Desktop Agent
echo Build Script
echo ========================================
echo.

REM Verificar que Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python no está instalado o no está en PATH
    pause
    exit /b 1
)

REM Verificar que PyInstaller está instalado
pip show pyinstaller >nul 2>&1
if errorlevel 1 (
    echo PyInstaller no está instalado. Instalando...
    pip install pyinstaller
)

echo Limpiando builds anteriores...
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist *.spec del /q *.spec

echo.
echo Compilando Desktop Agent...
echo.

REM Compilar con PyInstaller
REM --onefile: genera un único ejecutable
REM --noconsole: sin ventana de consola (para producción)
REM --icon: ícono del ejecutable (opcional)
REM --add-data: incluir archivos adicionales
REM --hidden-import: módulos que PyInstaller no detecta automáticamente

pyinstaller --onefile ^
    --name=CentroDiagnosticoAgent ^
    --add-data "config.example.json;." ^
    --add-data "collectors;collectors" ^
    --add-data "parsers;parsers" ^
    --hidden-import=serial ^
    --hidden-import=serial.tools.list_ports ^
    --hidden-import=watchdog ^
    --hidden-import=watchdog.observers ^
    --hidden-import=pydicom ^
    --hidden-import=hl7 ^
    agent.py

if errorlevel 1 (
    echo.
    echo ERROR: La compilación falló
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completado exitosamente!
echo ========================================
echo.
echo El ejecutable está en: dist\CentroDiagnosticoAgent.exe
echo.
echo Archivos necesarios para distribución:
echo   - dist\CentroDiagnosticoAgent.exe
echo   - config.example.json (renombrar a config.json)
echo.

REM Copiar config.example.json al directorio dist
copy config.example.json dist\config.example.json

echo El instalador se puede generar con Inno Setup usando installer.iss
echo.
pause
