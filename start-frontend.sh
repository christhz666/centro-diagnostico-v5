#!/bin/bash

# Script para iniciar Frontend

cd ~/centro-diagnostico/frontend

echo "=========================================="
echo "   CENTRO DIAGNÓSTICO - FRONTEND"
echo "=========================================="
echo ""

# Instalar dependencias si no existen
if [ ! -d "node_modules" ]; then
    echo "Instalando dependencias de npm..."
    npm install
fi

# Ejecutar
echo "? Iniciando React..."
npm start
