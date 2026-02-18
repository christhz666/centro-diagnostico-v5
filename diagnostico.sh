#!/bin/bash

echo "=========================================="
echo "   DIAGNÓSTICO DEL SISTEMA"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# PostgreSQL
echo -n "PostgreSQL: "
if systemctl is-active --quiet postgresql; then
    echo -e "${GREEN}? Activo${NC}"
else
    echo -e "${RED}? Inactivo${NC}"
fi

# Python
echo -n "Python: "
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}? $(python3 --version)${NC}"
else
    echo -e "${RED}? No instalado${NC}"
fi

# Venv
echo -n "Venv: "
if [ -d "backend/venv" ]; then
    echo -e "${GREEN}? Existe${NC}"
else
    echo -e "${RED}? No existe${NC}"
fi

# .env
echo -n ".env: "
if [ -f "backend/.env" ]; then
    echo -e "${GREEN}? Existe${NC}"
else
    echo -e "${RED}? No existe${NC}"
fi

# Backend corriendo
echo -n "Backend (5000): "
if curl -s http://localhost:5000/api/health &> /dev/null; then
    echo -e "${GREEN}? Respondiendo${NC}"
else
    echo -e "${RED}? No responde${NC}"
fi

# Frontend corriendo
echo -n "Frontend (3000): "
if curl -s http://localhost:3000 &> /dev/null; then
    echo -e "${GREEN}? Respondiendo${NC}"
else
    echo -e "${RED}? No responde${NC}"
fi

echo ""
echo "=========================================="
