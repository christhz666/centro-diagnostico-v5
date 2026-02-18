#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "+----------------------------------------------------------------+"
echo "¦     ?? DIAGNÓSTICO COMPLETO - CENTRO DIAGNÓSTICO MI ESPERANZA ¦"
echo "+----------------------------------------------------------------+"
echo ""
echo "Fecha: $(date)"
echo "Servidor: $(hostname)"
echo "IP: $(hostname -I | awk '{print $1}')"
echo ""

# Contadores
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

check_pass() {
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
    echo -e "${GREEN}? $1${NC}"
}

check_fail() {
    ((TOTAL_CHECKS++))
    ((FAILED_CHECKS++))
    echo -e "${RED}? $1${NC}"
}

check_warn() {
    ((TOTAL_CHECKS++))
    ((WARNING_CHECKS++))
    echo -e "${YELLOW}??  $1${NC}"
}

echo "----------------------------------------------------------------"
echo "1??  SISTEMA OPERATIVO Y RECURSOS"
echo "----------------------------------------------------------------"

# SO
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"

# CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
echo "CPU Usage: ${CPU_USAGE}%"
if (( $(echo "$CPU_USAGE < 80" | bc -l) )); then
    check_pass "CPU usage normal (${CPU_USAGE}%)"
else
    check_warn "CPU usage alto (${CPU_USAGE}%)"
fi

# Memoria
MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
MEM_USED=$(free -h | grep Mem | awk '{print $3}')
MEM_PERCENT=$(free | grep Mem | awk '{printf("%.0f"), $3/$2 * 100}')
echo "Memoria: ${MEM_USED} / ${MEM_TOTAL} (${MEM_PERCENT}%)"
if [ $MEM_PERCENT -lt 90 ]; then
    check_pass "Memoria disponible suficiente"
else
    check_warn "Memoria alta (${MEM_PERCENT}%)"
fi

# Disco
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
echo "Disco /: $(df -h / | tail -1 | awk '{print $3 " / " $2}') (${DISK_USAGE}%)"
if [ $DISK_USAGE -lt 85 ]; then
    check_pass "Espacio en disco suficiente"
else
    check_warn "Espacio en disco bajo (${DISK_USAGE}%)"
fi

echo ""
echo "----------------------------------------------------------------"
echo "2??  POSTGRESQL - BASE DE DATOS"
echo "----------------------------------------------------------------"

# Servicio PostgreSQL
if systemctl is-active --quiet postgresql; then
    check_pass "Servicio PostgreSQL activo"
else
    check_fail "Servicio PostgreSQL NO activo"
fi

# Puerto 5432
if ss -tuln | grep -q ":5432 "; then
    check_pass "Puerto 5432 escuchando"
else
    check_fail "Puerto 5432 NO escuchando"
fi

# Conexión a BD
if PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost -c "SELECT 1;" > /dev/null 2>&1; then
    check_pass "Conexión a base de datos exitosa"
    
    # Contar registros en tablas principales
    echo ""
    echo "?? Datos en tablas:"
    
    PACIENTES=$(PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost -t -c "SELECT COUNT(*) FROM pacientes;" 2>/dev/null | xargs)
    echo "   Pacientes: $PACIENTES"
    [ "$PACIENTES" -gt 0 ] && check_pass "$PACIENTES pacientes registrados" || check_warn "0 pacientes"
    
    ORDENES=$(PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost -t -c "SELECT COUNT(*) FROM ordenes;" 2>/dev/null | xargs)
    echo "   Órdenes: $ORDENES"
    [ "$ORDENES" -gt 0 ] && check_pass "$ORDENES órdenes registradas" || check_warn "0 órdenes"
    
    ESTUDIOS=$(PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost -t -c "SELECT COUNT(*) FROM estudios;" 2>/dev/null | xargs)
    echo "   Estudios: $ESTUDIOS"
    [ "$ESTUDIOS" -gt 0 ] && check_pass "$ESTUDIOS estudios en catálogo" || check_fail "0 estudios"
    
    USUARIOS=$(PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost -t -c "SELECT COUNT(*) FROM usuarios;" 2>/dev/null | xargs)
    echo "   Usuarios: $USUARIOS"
    [ "$USUARIOS" -gt 0 ] && check_pass "$USUARIOS usuarios registrados" || check_fail "0 usuarios"
    
    RESULTADOS=$(PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost -t -c "SELECT COUNT(*) FROM resultados;" 2>/dev/null | xargs)
    echo "   Resultados: $RESULTADOS"
    
    FACTURAS=$(PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost -t -c "SELECT COUNT(*) FROM facturas;" 2>/dev/null | xargs)
    echo "   Facturas: $FACTURAS"
    
else
    check_fail "NO se puede conectar a la base de datos"
fi

echo ""
echo "----------------------------------------------------------------"
echo "3??  BACKEND - API PYTHON/FLASK"
echo "----------------------------------------------------------------"

# Servicio backend
if systemctl is-active --quiet centro-backend; then
    check_pass "Servicio centro-backend activo"
    
    # PID y uso de recursos
    BACKEND_PID=$(systemctl show -p MainPID centro-backend | cut -d= -f2)
    echo "   PID: $BACKEND_PID"
    
else
    check_fail "Servicio centro-backend NO activo"
fi

# Puerto 5000
if ss -tuln | grep -q "127.0.0.1:5000"; then
    check_pass "Puerto 5000 escuchando"
else
    check_fail "Puerto 5000 NO escuchando"
fi

# Archivos del backend
[ -f backend/run.py ] && check_pass "Archivo run.py existe" || check_fail "run.py NO existe"
[ -f backend/.env ] && check_pass "Archivo .env existe" || check_warn ".env NO existe"
[ -d backend/venv ] && check_pass "Virtual environment existe" || check_fail "venv NO existe"

# Probar login
echo ""
echo "?? Probando endpoint de login..."
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin123!"}' 2>&1)

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
BODY=$(echo "$LOGIN_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    check_pass "Login endpoint funciona (HTTP 200)"
    
    # Verificar token
    TOKEN=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null)
    if [ -n "$TOKEN" ]; then
        check_pass "Token JWT generado correctamente"
        echo "   Token: ${TOKEN:0:50}..."
        
        # Probar endpoints protegidos con el token
        echo ""
        echo "?? Probando endpoints protegidos:"
        
        # Dashboard stats
        STATS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/dashboard/stats)
        [ "$STATS_CODE" = "200" ] && check_pass "GET /api/dashboard/stats (HTTP $STATS_CODE)" || check_fail "GET /api/dashboard/stats (HTTP $STATS_CODE)"
        
        # Citas hoy
        CITAS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/citas/hoy)
        [ "$CITAS_CODE" = "200" ] && check_pass "GET /api/citas/hoy (HTTP $CITAS_CODE)" || check_fail "GET /api/citas/hoy (HTTP $CITAS_CODE)"
        
        # Pacientes
        PACIENTES_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/pacientes/)
        [ "$PACIENTES_CODE" = "200" ] && check_pass "GET /api/pacientes/ (HTTP $PACIENTES_CODE)" || check_warn "GET /api/pacientes/ (HTTP $PACIENTES_CODE)"
        
        # Estudios
        ESTUDIOS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/estudios/)
        [ "$ESTUDIOS_CODE" = "200" ] && check_pass "GET /api/estudios/ (HTTP $ESTUDIOS_CODE)" || check_warn "GET /api/estudios/ (HTTP $ESTUDIOS_CODE)"
        
        # Resultados
        RESULTADOS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/resultados/)
        [ "$RESULTADOS_CODE" = "200" ] && check_pass "GET /api/resultados/ (HTTP $RESULTADOS_CODE)" || check_warn "GET /api/resultados/ (HTTP $RESULTADOS_CODE)"
        
        # Radiografías
        RADIOS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/radiografias/)
        [ "$RADIOS_CODE" = "200" ] && check_pass "GET /api/radiografias/ (HTTP $RADIOS_CODE)" || check_warn "GET /api/radiografias/ (HTTP $RADIOS_CODE)"
        
        # Sonografías
        SONOS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/sonografias/)
        [ "$SONOS_CODE" = "200" ] && check_pass "GET /api/sonografias/ (HTTP $SONOS_CODE)" || check_warn "GET /api/sonografias/ (HTTP $SONOS_CODE)"
        
        # WhatsApp
        WHATS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/whatsapp/historial)
        [ "$WHATS_CODE" = "200" ] && check_pass "GET /api/whatsapp/historial (HTTP $WHATS_CODE)" || check_warn "GET /api/whatsapp/historial (HTTP $WHATS_CODE)"
        
    else
        check_fail "Token NO generado"
    fi
else
    check_fail "Login endpoint falló (HTTP $HTTP_CODE)"
    echo "   Respuesta: $BODY"
fi

# Rutas registradas
echo ""
echo "?? Rutas registradas en backend:"
ROUTES_COUNT=$(grep -c "'app.routes" backend/run.py 2>/dev/null || echo "0")
echo "   Total de blueprints: $ROUTES_COUNT"
[ "$ROUTES_COUNT" -gt 15 ] && check_pass "$ROUTES_COUNT rutas registradas" || check_warn "Solo $ROUTES_COUNT rutas"

echo ""
echo "----------------------------------------------------------------"
echo "4??  FRONTEND - REACT"
echo "----------------------------------------------------------------"

# Puerto 3000
if ss -tuln | grep -q ":3000 "; then
    check_pass "Puerto 3000 escuchando"
else
    check_fail "Puerto 3000 NO escuchando"
fi

# Proceso React
if ps aux | grep -v grep | grep -q "react-scripts"; then
    check_pass "Proceso react-scripts corriendo"
    REACT_PID=$(ps aux | grep react-scripts | grep -v grep | head -1 | awk '{print $2}')
    echo "   PID: $REACT_PID"
else
    check_fail "Proceso react-scripts NO corriendo"
fi

# Respuesta del frontend
FRONT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
if [ "$FRONT_RESPONSE" = "200" ]; then
    check_pass "Frontend responde (HTTP 200)"
else
    check_fail "Frontend NO responde (HTTP $FRONT_RESPONSE)"
fi

# Archivos clave
echo ""
echo "?? Archivos del frontend:"
[ -f frontend/package.json ] && check_pass "package.json existe" || check_fail "package.json NO existe"
[ -f frontend/src/App.js ] && check_pass "App.js existe" || check_fail "App.js NO existe"
[ -f frontend/src/components/Login.js ] && check_pass "Login.js existe" || check_fail "Login.js NO existe"
[ -f frontend/src/components/Dashboard.js ] && check_pass "Dashboard.js existe" || check_fail "Dashboard.js NO existe"
[ -f frontend/src/services/api.js ] && check_pass "api.js existe" || check_fail "api.js NO existe"

# Verificar configuración de API
if [ -f frontend/src/services/api.js ]; then
    API_URL=$(grep -o "API_URL.*=.*['\"].*['\"]" frontend/src/services/api.js | head -1)
    echo "   API URL configurada: $API_URL"
    if echo "$API_URL" | grep -q "/api"; then
        check_pass "API URL configurada correctamente"
    else
        check_warn "API URL puede tener problemas"
    fi
fi

# Node modules
if [ -d frontend/node_modules ]; then
    MODULES_COUNT=$(ls -1 frontend/node_modules | wc -l)
    check_pass "node_modules instalado ($MODULES_COUNT paquetes)"
else
    check_fail "node_modules NO existe"
fi

echo ""
echo "----------------------------------------------------------------"
echo "5??  NGINX - PROXY REVERSO"
echo "----------------------------------------------------------------"

# Servicio NGINX
if systemctl is-active --quiet nginx; then
    check_pass "Servicio NGINX activo"
else
    check_fail "Servicio NGINX NO activo"
fi

# Puerto 80
if ss -tuln | grep -q ":80 "; then
    check_pass "Puerto 80 escuchando"
else
    check_fail "Puerto 80 NO escuchando"
fi

# Archivo de configuración
if [ -f /etc/nginx/conf.d/centro-diagnostico.conf ]; then
    check_pass "Archivo de configuración existe"
    
    # Verificar puerto en config
    PROXY_PORT=$(grep "proxy_pass.*300" /etc/nginx/conf.d/centro-diagnostico.conf | head -1 | grep -o "300[0-9]")
    echo "   Proxy frontend al puerto: $PROXY_PORT"
    [ "$PROXY_PORT" = "3000" ] && check_pass "Proxy configurado al puerto correcto" || check_warn "Proxy configurado al puerto $PROXY_PORT"
    
else
    check_fail "Archivo de configuración NO existe"
fi

# Test de sintaxis NGINX
if sudo nginx -t > /dev/null 2>&1; then
    check_pass "Configuración NGINX válida"
else
    check_fail "Configuración NGINX tiene errores"
fi

# Probar proxy
NGINX_FRONT=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
[ "$NGINX_FRONT" = "200" ] && check_pass "NGINX proxy frontend (HTTP 200)" || check_fail "NGINX proxy frontend (HTTP $NGINX_FRONT)"

NGINX_API=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/api/auth/login -H "Content-Type: application/json" -d '{"username":"test","password":"test"}')
[ "$NGINX_API" != "000" ] && check_pass "NGINX proxy API (HTTP $NGINX_API)" || check_fail "NGINX proxy API no responde"

echo ""
echo "----------------------------------------------------------------"
echo "6??  ACCESO EXTERNO"
echo "----------------------------------------------------------------"

# Firewall
if systemctl is-active --quiet firewalld; then
    check_pass "Firewalld activo"
    
    # Verificar puerto 80
    if sudo firewall-cmd --list-ports 2>/dev/null | grep -q "80/tcp"; then
        check_pass "Puerto 80 abierto en firewall"
    else
        check_warn "Puerto 80 podría no estar abierto"
    fi
else
    check_warn "Firewalld no está activo"
fi

# Test desde localhost
EXTERNAL_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://192.9.135.84)
if [ "$EXTERNAL_TEST" = "200" ]; then
    check_pass "Acceso por IP pública funciona (HTTP 200)"
else
    check_warn "Acceso por IP pública (HTTP $EXTERNAL_TEST)"
fi

echo ""
echo "----------------------------------------------------------------"
echo "7??  SEGURIDAD Y CONFIGURACIÓN"
echo "----------------------------------------------------------------"

# SELinux
SELINUX_STATUS=$(getenforce 2>/dev/null || echo "No disponible")
echo "SELinux: $SELINUX_STATUS"
[ "$SELINUX_STATUS" = "Enforcing" ] && check_pass "SELinux activo" || check_warn "SELinux: $SELINUX_STATUS"

# Variables de entorno del backend
if [ -f backend/.env ]; then
    if grep -q "JWT_SECRET_KEY" backend/.env; then
        check_pass "JWT_SECRET_KEY configurado"
    else
        check_warn "JWT_SECRET_KEY no encontrado"
    fi
    
    if grep -q "DATABASE_URL" backend/.env; then
        check_pass "DATABASE_URL configurado"
    else
        check_fail "DATABASE_URL no encontrado"
    fi
fi

echo ""
echo "----------------------------------------------------------------"
echo "8??  LOGS Y MONITOREO"
echo "----------------------------------------------------------------"

# Logs del backend
if journalctl -u centro-backend -n 1 > /dev/null 2>&1; then
    check_pass "Logs de backend accesibles"
    
    # Buscar errores recientes
    ERROR_COUNT=$(sudo journalctl -u centro-backend --since "10 minutes ago" | grep -ci "error\|exception\|traceback" || echo "0")
    if [ "$ERROR_COUNT" -eq 0 ]; then
        check_pass "No hay errores recientes en backend"
    else
        check_warn "$ERROR_COUNT errores en últimos 10 minutos"
    fi
else
    check_warn "No se pueden acceder logs del backend"
fi

# Logs del frontend
if [ -f frontend/frontend.log ]; then
    check_pass "Log del frontend existe"
    
    # Tamaño del log
    LOG_SIZE=$(du -h frontend/frontend.log | cut -f1)
    echo "   Tamaño del log: $LOG_SIZE"
else
    check_warn "Log del frontend no existe"
fi

# Logs de NGINX
if [ -f /var/log/nginx/error.log ]; then
    check_pass "Logs de NGINX accesibles"
    
    # Errores recientes
    NGINX_ERRORS=$(sudo tail -100 /var/log/nginx/error.log | grep -c "error" || echo "0")
    if [ "$NGINX_ERRORS" -lt 10 ]; then
        check_pass "Pocos errores en NGINX ($NGINX_ERRORS)"
    else
        check_warn "$NGINX_ERRORS errores en log de NGINX"
    fi
fi

echo ""
echo "----------------------------------------------------------------"
echo "?? RESUMEN FINAL"
echo "----------------------------------------------------------------"
echo ""
echo "Total de verificaciones: $TOTAL_CHECKS"
echo -e "${GREEN}? Pasadas: $PASSED_CHECKS${NC}"
echo -e "${YELLOW}??  Advertencias: $WARNING_CHECKS${NC}"
echo -e "${RED}? Fallidas: $FAILED_CHECKS${NC}"
echo ""

# Calcular porcentaje
PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
echo "Nivel de salud del sistema: $PERCENTAGE%"

if [ $PERCENTAGE -ge 90 ]; then
    echo -e "${GREEN}?? Sistema en excelente estado${NC}"
elif [ $PERCENTAGE -ge 75 ]; then
    echo -e "${YELLOW}??  Sistema funcional con advertencias${NC}"
else
    echo -e "${RED}? Sistema requiere atención${NC}"
fi

echo ""
echo "----------------------------------------------------------------"
echo "?? INFORMACIÓN DE ACCESO"
echo "----------------------------------------------------------------"
echo ""
echo "URL Principal: http://192.9.135.84"
echo ""
echo "Credenciales de prueba:"
echo "  Email: admin@miesperanza.com"
echo "  Password: Admin123!"
echo ""
echo "Puertos:"
echo "  - Frontend: 3000"
echo "  - Backend: 5000"
echo "  - NGINX: 80"
echo "  - PostgreSQL: 5432"
echo ""
echo "----------------------------------------------------------------"

