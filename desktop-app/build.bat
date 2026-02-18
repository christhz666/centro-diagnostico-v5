@echo off
REM Build script para Desktop App (Electron)
REM Genera un instalador para Windows

echo ========================================
echo Centro Diagnostico v5 - Desktop App
echo Build Script
echo ========================================
echo.

REM Verificar que Node.js está instalado
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js no está instalado o no está en PATH
    echo Por favor instale Node.js desde https://nodejs.org/
    pause
    exit /b 1
)

REM Verificar que npm está instalado
npm --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: npm no está instalado
    pause
    exit /b 1
)

echo Instalando dependencias...
call npm install

if errorlevel 1 (
    echo ERROR: Falló la instalación de dependencias
    pause
    exit /b 1
)

echo.
echo Limpiando builds anteriores...
if exist dist rmdir /s /q dist

echo.
echo Compilando aplicación de escritorio para Windows...
echo.

REM Build para Windows
call npm run build:win

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
echo El instalador está en: dist\Centro Diagnóstico Setup 5.0.0.exe
echo.
pause
