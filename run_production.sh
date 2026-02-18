#!/bin/bash

echo ""
echo "===== INICIANDO CENTRO DIAGNÓSTICO ====="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ========== VERIFICAR POSTGRESQL ==========
echo "[1/3] Verificando PostgreSQL..."
if ! pg_isready -h localhost &> /dev/null; then
    echo -e "${RED}? PostgreSQL no está corriendo${NC}"
    echo "Inicia con: sudo systemctl start postgresql"
    exit 1
fi
echo -e "${GREEN}? PostgreSQL OK${NC}"

# ========== ARRANCAR BACKEND (FLASK) ==========
echo "[2/3] Iniciando Backend (Flask)..."
cd backend

# Activar venv
source venv/bin/activate

# Crear logs
mkdir -p logs

# Ejecutar con gunicorn en producción
if [ "$1" == "dev" ]; then
    # Modo desarrollo
    python run.py
else
    # Modo producción
    gunicorn -w 4 -b 0.0.0.0:5000 --access-logfile logs/access.log --error-logfile logs/error.log run:create_app
fi
