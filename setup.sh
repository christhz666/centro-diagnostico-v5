#!/bin/bash

# ================================================
# SCRIPT DE INICIO RÁPIDO
# Centro Diagnóstico - Sistema de Gestión
# ================================================

echo "=============================================="
echo "   CENTRO DIAGNÓSTICO - INICIO RÁPIDO"
echo "=============================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para imprimir con colores
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verificar si estamos en el directorio correcto
if [ ! -f "backend/requirements.txt" ]; then
    print_error "Error: Ejecuta este script desde la raíz del proyecto"
    exit 1
fi

# PASO 1: Verificar PostgreSQL
echo "1. Verificando PostgreSQL..."
if command -v psql &> /dev/null; then
    print_success "PostgreSQL está instalado"
else
    print_error "PostgreSQL no está instalado"
    echo "Instala PostgreSQL con: sudo apt install postgresql postgresql-contrib"
    exit 1
fi

# PASO 2: Verificar Python
echo ""
echo "2. Verificando Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_success "Python está instalado: $PYTHON_VERSION"
else
    print_error "Python 3 no está instalado"
    exit 1
fi

# PASO 3: Crear entorno virtual
echo ""
echo "3. Configurando entorno virtual..."
cd backend

if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "Entorno virtual creado"
else
    print_warning "Entorno virtual ya existe"
fi

# Activar entorno virtual
source venv/bin/activate
print_success "Entorno virtual activado"

# PASO 4: Instalar dependencias
echo ""
echo "4. Instalando dependencias Python..."
pip install -r requirements.txt > /dev/null 2>&1
print_success "Dependencias instaladas"

# PASO 5: Configurar variables de entorno
echo ""
echo "5. Configurando variables de entorno..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    print_warning "Archivo .env creado desde .env.example"
    print_warning "IMPORTANTE: Edita el archivo .env con tus configuraciones"
else
    print_success "Archivo .env ya existe"
fi

# PASO 6: Crear base de datos
echo ""
echo "6. Configurando base de datos..."
read -p "¿Deseas crear la base de datos ahora? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Ingresa la contraseña de PostgreSQL cuando se solicite..."
    
    sudo -u postgres psql << EOF
CREATE DATABASE centro_diagnostico;
CREATE USER centro_user WITH PASSWORD 'centro_pass_2025';
GRANT ALL PRIVILEGES ON DATABASE centro_diagnostico TO centro_user;
ALTER DATABASE centro_diagnostico OWNER TO centro_user;
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Base de datos creada"
        
        # Ejecutar schema
        echo "Ejecutando schema..."
        PGPASSWORD=centro_pass_2025 psql -U centro_user -d centro_diagnostico -f ../database/schema.sql > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            print_success "Schema ejecutado correctamente"
        else
            print_error "Error al ejecutar schema"
        fi
    else
        print_error "Error al crear base de datos"
    fi
else
    print_warning "Base de datos omitida. Debes crearla manualmente."
fi

# PASO 7: Verificar Redis (opcional)
echo ""
echo "7. Verificando Redis..."
if command -v redis-cli &> /dev/null; then
    redis-cli ping > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "Redis está corriendo"
    else
        print_warning "Redis está instalado pero no está corriendo"
        echo "Inicia Redis con: sudo systemctl start redis"
    fi
else
    print_warning "Redis no está instalado (opcional para tareas asíncronas)"
    echo "Instala con: sudo apt install redis-server"
fi

# PASO 8: Crear carpetas necesarias
echo ""
echo "8. Creando estructura de carpetas..."
mkdir -p uploads/resultados
mkdir -p uploads/temp
print_success "Carpetas creadas"

# RESUMEN FINAL
echo ""
echo "=============================================="
echo "   ✓ INSTALACIÓN COMPLETADA"
echo "=============================================="
echo ""
echo "Próximos pasos:"
echo ""
echo "1. Edita el archivo backend/.env con tus configuraciones"
echo "2. Inicia el servidor:"
echo "   cd backend"
echo "   source venv/bin/activate"
echo "   python app.py"
echo ""
echo "3. El servidor estará disponible en:"
echo "   http://localhost:5000"
echo ""
echo "4. Usuario por defecto:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "5. Endpoints principales:"
echo "   POST http://localhost:5000/api/auth/login"
echo "   GET  http://localhost:5000/api/health"
echo "   GET  http://localhost:5000/api/facturas/"
echo ""
echo "6. Documentación completa:"
echo "   docs/README.md"
echo ""
echo "=============================================="
