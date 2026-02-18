#!/bin/bash

echo "+---------------------------------------+"
echo "¦   PRUEBA FINAL DEL SISTEMA            ¦"
echo "+---------------------------------------+"
echo ""

# Test 1: Base de datos
echo "1. Base de datos..."
PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>&1 | grep -q "count"
if [ $? -eq 0 ]; then
    echo "   ? Base de datos OK"
else
    echo "   ? Base de datos FALLO"
fi

# Test 2: Backend health
echo "2. Backend health..."
HEALTH=$(curl -s http://localhost:5000/api/health)
if echo "$HEALTH" | grep -q "ok"; then
    echo "   ? Backend OK"
    echo "   $HEALTH"
else
    echo "   ? Backend FALLO"
fi

# Test 3: Frontend
echo "3. Frontend..."
curl -s http://localhost:3000 > /dev/null
if [ $? -eq 0 ]; then
    echo "   ? Frontend OK"
else
    echo "   ? Frontend FALLO"
fi

# Test 4: Twilio instalado
echo "4. Módulo Twilio..."
cd backend
source venv/bin/activate
python3 -c "import twilio; print('   ? Twilio OK')" 2>/dev/null || echo "   ? Twilio FALLO"
deactivate
cd ..

# Test 5: Analytics route
echo "5. Analytics route..."
cd backend
source venv/bin/activate
python3 -c "from app.routes.analytics import analytics_bp; print('   ? Analytics OK')" 2>/dev/null || echo "   ? Analytics FALLO"
deactivate
cd ..

echo ""
echo "+---------------------------------------+"
echo "¦            ACCESO AL SISTEMA          ¦"
echo "+---------------------------------------+"
echo ""
echo "?? Frontend: http://192.9.135.84:3000"
echo "??  Backend:  http://192.9.135.84:5000"
echo "?? Health:   http://192.9.135.84:5000/api/health"
echo ""
echo "?? Usuario: admin"
echo "?? Password: admin123"
echo ""
