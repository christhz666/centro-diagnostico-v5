#!/bin/bash

echo ""
echo "=========================================="
echo "   CENTRO DIAGNÓSTICO - SISTEMA COMPLETO"
echo "=========================================="
echo ""

# Verificar PostgreSQL
echo "[1/3] Verificando PostgreSQL..."
if ! systemctl is-active --quiet postgresql; then
    echo "? PostgreSQL no está activo"
    echo "Iniciando PostgreSQL..."
    sudo systemctl start postgresql
fi
echo "? PostgreSQL OK"

# Iniciar Backend en background
echo ""
echo "[2/3] Iniciando Backend..."
cd ~/centro-diagnostico
bash start-backend.sh &
BACKEND_PID=$!
sleep 3
echo "? Backend corriendo (PID: $BACKEND_PID)"

# Iniciar Frontend en background
echo ""
echo "[3/3] Iniciando Frontend..."
bash start-frontend.sh &
FRONTEND_PID=$!
echo "? Frontend corriendo (PID: $FRONTEND_PID)"

echo ""
echo "=========================================="
echo "   ? SISTEMA INICIADO"
echo "=========================================="
echo ""
echo "Acceso:"
echo "  Frontend: http://localhost:3000"
echo "  Backend:  http://localhost:5000"
echo "  API Docs: http://localhost:5000/api/health"
echo ""
echo "Logs:"
echo "  Backend:  tail -f backend/logs/access.log"
echo "  Frontend: tail -f frontend/npm-debug.log"
echo ""
echo "Para detener:"
echo "  kill $BACKEND_PID $FRONTEND_PID"
echo ""

# Mantener activo
wait
