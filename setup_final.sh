#!/bin/bash

echo "=========================================="
echo "   INSTALACIÓN COMPLETA - CENTRO DIAGNÓSTICO"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Variables de control
ERRORS=0

# Función para imprimir
print_success() { echo -e "${GREEN}? $1${NC}"; }
print_warn() { echo -e "${YELLOW}? $1${NC}"; }
print_error() { echo -e "${RED}? $1${NC}"; ((ERRORS++)); }

# ========== 1. VERIFICAR POSTGRESQL ==========
echo ""
echo "[1/7] Verificando PostgreSQL..."
if command -v psql &> /dev/null; then
    print_success "PostgreSQL está instalado"
    if pg_isready -h localhost -U centro_user -d centro_diagnostico &> /dev/null; then
        print_success "Conexión a BD exitosa"
    else
        print_warn "No se conecta a BD. Verifica credenciales en .env"
    fi
else
    print_error "PostgreSQL NO instalado. Instala: sudo apt install postgresql postgresql-contrib"
fi

# ========== 2. VERIFICAR PYTHON ==========
echo ""
echo "[2/7] Verificando Python..."
if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version)
    print_success "Python: $PY_VERSION"
else
    print_error "Python 3 NO instalado"
fi

# ========== 3. CREAR ENTORNO VIRTUAL ==========
echo ""
echo "[3/7] Configurando entorno virtual..."
cd backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "Entorno virtual creado"
else
    print_warn "Entorno virtual ya existe"
fi

# Activar
source venv/bin/activate
print_success "Entorno activado"

# ========== 4. INSTALAR DEPENDENCIAS ==========
echo ""
echo "[4/7] Instalando dependencias Python..."
pip install --upgrade pip -q
pip install -r requirements.txt -q
if [ $? -eq 0 ]; then
    print_success "Dependencias instaladas"
else
    print_error "Error al instalar dependencias"
fi

# ========== 5. CREAR CARPETAS ==========
echo ""
echo "[5/7] Creando estructura de carpetas..."
mkdir -p uploads/resultados uploads/temp uploads/equipos logs
print_success "Carpetas creadas"

# ========== 6. VERIFICAR .env ==========
echo ""
echo "[6/7] Verificando configuración..."
if [ -f ".env" ]; then
    print_success "Archivo .env existe"
    
    if grep -q "DATABASE_URL" .env; then
        print_success "DATABASE_URL configurado"
    else
        print_error "DATABASE_URL no encontrado en .env"
    fi
    
    if grep -q "SECRET_KEY" .env && ! grep "SECRET_KEY=cambiar" .env; then
        print_success "SECRET_KEY configurado"
    else
        print_error "SECRET_KEY sin configurar o con valor por defecto"
    fi
else
    print_error "Archivo .env NO existe. Copia desde .env.example y edita"
fi

# ========== 7. PRUEBA DE CONEXIÓN BD ==========
echo ""
echo "[7/7] Probando conexión a base de datos..."
python3 << PYEOF
import os
from dotenv import load_dotenv
load_dotenv()

try:
    import psycopg2
    conn = psycopg2.connect(os.getenv('DATABASE_URL'))
    print("? Conexión a PostgreSQL exitosa")
    conn.close()
except Exception as e:
    print(f"? Error de conexión: {e}")
PYEOF

# ========== RESUMEN ==========
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}? INSTALACIÓN COMPLETADA${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "1. Edita backend/.env con tus credenciales reales"
    echo "2. Ejecuta migraciones: cd backend && flask db upgrade"
    echo "3. Inicia servidor: python run.py"
    echo "4. Frontend: cd frontend && npm install && npm start"
else
    echo -e "${RED}? ERRORES ENCONTRADOS: $ERRORS${NC}"
    echo "Revisa los mensajes arriba y corrige"
fi
echo "=========================================="
