#!/bin/bash

# Script para iniciar Centro Diagnóstico en producción

cd ~/centro-diagnostico/backend

echo "=========================================="
echo "   CENTRO DIAGNÓSTICO - BACKEND"
echo "=========================================="
echo ""

# Activar venv
source venv/bin/activate

# Crear logs
mkdir -p logs

# Ejecutar con gunicorn
echo "? Iniciando con Gunicorn (4 workers)..."
gunicorn -w 4 -b 0.0.0.0:5000 --access-logfile logs/access.log --error-logfile logs/error.log 'run:app'
