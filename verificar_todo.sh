#!/bin/bash

echo "?? VERIFICACIÓN COMPLETA DEL SISTEMA"
echo "===================================="
echo ""

# Test 1: Base de datos
echo "1?? Probando conexión a base de datos..."
psql postgresql://centro_user:Centro2024!@localhost/centro_diagnostico -c "SELECT NOW();" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ? Base de datos conectada"
else
    echo "   ? Base de datos NO conectada"
fi

# Test 2: Backend health
echo "2?? Probando backend health check..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/health)
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ? Backend respondiendo correctamente"
else
    echo "   ? Backend NO responde (HTTP $HTTP_CODE)"
fi

# Test 3: Frontend
echo "3?? Probando frontend..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ? Frontend respondiendo correctamente"
else
    echo "   ? Frontend NO responde (HTTP $HTTP_CODE)"
fi

# Test 4: Módulos Python
echo "4?? Verificando módulos Python..."
cd backend
source venv/bin/activate
python3 -c "from app import create_app; print('? create_app funciona')" 2>&1 | grep -q "?"
if [ $? -eq 0 ]; then
    echo "   ? Módulos Python OK"
else
    echo "   ? Problemas con módulos Python"
fi
deactivate
cd ..

echo ""
echo "?? RESULTADO FINAL:"
echo "==================="
echo "Accede al sistema en:"
echo "  ?? Frontend: http://192.9.135.84:3000"
echo "  ??  Backend:  http://192.9.135.84:5000"
echo ""
