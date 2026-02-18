@echo off
REM Build script para Label Printer
REM Genera un ejecutable standalone usando PyInstaller

echo ========================================
echo Centro Diagnostico v5 - Label Printer
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
echo Compilando Label Printer...
echo.

REM Compilar con PyInstaller
pyinstaller --onefile ^
    --windowed ^
    --name=LabelPrinter ^
    --hidden-import=PIL ^
    --hidden-import=PIL._tkinter_finder ^
    --hidden-import=tkinter ^
    --hidden-import=barcode ^
    --hidden-import=barcode.writer ^
    main.py

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
echo El ejecutable está en: dist\LabelPrinter.exe
echo.

REM Crear config.json de ejemplo en dist
echo { > dist\config.json
echo   "server_url": "http://192.9.135.84:5000/api", >> dist\config.json
echo   "printer_model": "Zebra GK420", >> dist\config.json
echo   "label_width_mm": 50, >> dist\config.json
echo   "label_height_mm": 25 >> dist\config.json
echo } >> dist\config.json

echo El instalador se puede generar con Inno Setup usando installer.iss
echo.
pause
