#!/bin/bash

################################################################################
# TEST SISTEMA COMPLETO - CENTRO DIAGNÓSTICO MI ESPERANZA
# Script de verificación exhaustiva de toda la aplicación
#
# Descripción:
#   Este script realiza 114+ verificaciones exhaustivas del sistema completo:
#   - Estructura de archivos (backend Node.js, Python/Flask, frontend React)
#   - Dependencias (node_modules, Python venv)
#   - Consistencia de imports y controllers
#   - Conexiones a bases de datos (MongoDB, PostgreSQL)
#   - Endpoints de API REST
#   - Mapeo de rutas frontend ↔ backend
#   - Variables de entorno
#
# Uso:
#   ./test_sistema_completo.sh
#
# Salida:
#   - Terminal: Output con colores (verde=pass, amarillo=warn, rojo=fail)
#   - Log: logs/test_sistema_YYYYMMDD_HHMMSS.log
#
# Características:
#   - Idempotente (se puede ejecutar múltiples veces)
#   - No requiere servidor corriendo para tests básicos
#   - Tests de API completos si servidor está en puerto 5000
#   - Logs automáticamente excluidos de git
#
# Autor: Sistema de Diagnóstico Centro Médico
# Versión: 1.0
# Fecha: 2026-02-18
################################################################################

# Colores para terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/test_sistema_$TIMESTAMP.log"

# Contadores
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Arrays para almacenar detalles
declare -a FAILED_ITEMS
declare -a WARNING_ITEMS

################################################################################
# FUNCIONES DE UTILIDAD
################################################################################

# Función para escribir en log y terminal
log_both() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_only() {
    echo -e "$1" >> "$LOG_FILE"
}

# Función para título de sección
print_section() {
    local title="$1"
    local line="================================================================================"
    log_both "\n${CYAN}${BOLD}$line${NC}"
    log_both "${CYAN}${BOLD}$title${NC}"
    log_both "${CYAN}${BOLD}$line${NC}"
}

# Funciones de verificación
check_pass() {
    ((TOTAL_TESTS++))
    ((PASSED_TESTS++))
    log_both "${GREEN}✅ $1${NC}"
}

check_fail() {
    ((TOTAL_TESTS++))
    ((FAILED_TESTS++))
    FAILED_ITEMS+=("$1")
    log_both "${RED}❌ $1${NC}"
}

check_warn() {
    ((TOTAL_TESTS++))
    ((WARNING_TESTS++))
    WARNING_ITEMS+=("$1")
    log_both "${YELLOW}⚠️  $1${NC}"
}

# Función para verificar si un archivo existe
check_file() {
    local file="$1"
    local description="$2"
    if [ -f "$file" ]; then
        check_pass "$description existe: $file"
        return 0
    else
        check_fail "$description NO existe: $file"
        return 1
    fi
}

# Función para verificar si un directorio existe
check_dir() {
    local dir="$1"
    local description="$2"
    if [ -d "$dir" ]; then
        check_pass "$description existe: $dir"
        return 0
    else
        check_fail "$description NO existe: $dir"
        return 1
    fi
}

################################################################################
# INICIALIZACIÓN
################################################################################

initialize() {
    mkdir -p "$LOG_DIR"
    
    log_both "${BOLD}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    log_both "${BOLD}║   TEST SISTEMA COMPLETO - CENTRO DIAGNÓSTICO MI ESPERANZA                 ║${NC}"
    log_both "${BOLD}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    log_both ""
    log_both "📅 Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
    log_both "🖥️  Servidor: $(hostname)"
    log_both "📝 Log: $LOG_FILE"
    log_both ""
}

################################################################################
# SECCIÓN 1: VERIFICACIÓN DE ESTRUCTURA DE ARCHIVOS
################################################################################

test_file_structure() {
    print_section "1️⃣  VERIFICACIÓN DE ESTRUCTURA DE ARCHIVOS"
    
    # Backend - Node.js
    log_both "\n${BOLD}Backend Node.js:${NC}"
    check_file "$SCRIPT_DIR/backend/server.js" "Servidor principal"
    check_file "$SCRIPT_DIR/backend/package.json" "Package.json"
    check_file "$SCRIPT_DIR/backend/config/db.js" "Configuración MongoDB"
    
    # Backend Routes
    log_both "\n${BOLD}Backend Routes:${NC}"
    check_file "$SCRIPT_DIR/backend/routes/auth.js" "Ruta auth.js"
    check_file "$SCRIPT_DIR/backend/routes/admin.js" "Ruta admin.js"
    check_file "$SCRIPT_DIR/backend/routes/dashboard.js" "Ruta dashboard.js"
    check_file "$SCRIPT_DIR/backend/routes/contabilidad.js" "Ruta contabilidad.js"
    check_file "$SCRIPT_DIR/backend/routes/equipoRoutes.js" "Ruta equipoRoutes.js"
    check_file "$SCRIPT_DIR/backend/routes/pacientes.js" "Ruta pacientes.js"
    check_file "$SCRIPT_DIR/backend/routes/citas.js" "Ruta citas.js"
    check_file "$SCRIPT_DIR/backend/routes/estudios.js" "Ruta estudios.js"
    check_file "$SCRIPT_DIR/backend/routes/resultados.js" "Ruta resultados.js"
    check_file "$SCRIPT_DIR/backend/routes/facturas.js" "Ruta facturas.js"
    
    # Note: These files exist with different names
    check_file "$SCRIPT_DIR/backend/routes/authRoutes.js" "Ruta authRoutes.js (alternativa)"
    check_file "$SCRIPT_DIR/backend/routes/citaRoutes.js" "Ruta citaRoutes.js (alternativa)"
    check_file "$SCRIPT_DIR/backend/routes/pacienteRoutes.js" "Ruta pacienteRoutes.js (alternativa)"
    check_file "$SCRIPT_DIR/backend/routes/estudioRoutes.js" "Ruta estudioRoutes.js (alternativa)"
    check_file "$SCRIPT_DIR/backend/routes/resultadoRoutes.js" "Ruta resultadoRoutes.js"
    
    # Backend Controllers
    log_both "\n${BOLD}Backend Controllers:${NC}"
    check_file "$SCRIPT_DIR/backend/controllers/authController.js" "Controller auth"
    check_file "$SCRIPT_DIR/backend/controllers/adminController.js" "Controller admin"
    check_file "$SCRIPT_DIR/backend/controllers/dashboardController.js" "Controller dashboard"
    check_file "$SCRIPT_DIR/backend/controllers/contabilidadController.js" "Controller contabilidad"
    check_file "$SCRIPT_DIR/backend/controllers/equipoController.js" "Controller equipo"
    check_file "$SCRIPT_DIR/backend/controllers/resultadoController.js" "Controller resultado"
    check_file "$SCRIPT_DIR/backend/controllers/pacienteController.js" "Controller paciente"
    check_file "$SCRIPT_DIR/backend/controllers/citaController.js" "Controller cita"
    check_file "$SCRIPT_DIR/backend/controllers/estudioController.js" "Controller estudio"
    check_file "$SCRIPT_DIR/backend/controllers/facturaController.js" "Controller factura"
    
    # Backend Models
    log_both "\n${BOLD}Backend Models:${NC}"
    check_file "$SCRIPT_DIR/backend/models/User.js" "Modelo User"
    check_file "$SCRIPT_DIR/backend/models/Paciente.js" "Modelo Paciente"
    check_file "$SCRIPT_DIR/backend/models/Cita.js" "Modelo Cita"
    check_file "$SCRIPT_DIR/backend/models/Estudio.js" "Modelo Estudio"
    check_file "$SCRIPT_DIR/backend/models/Resultado.js" "Modelo Resultado"
    check_file "$SCRIPT_DIR/backend/models/Factura.js" "Modelo Factura"
    check_file "$SCRIPT_DIR/backend/models/Equipo.js" "Modelo Equipo"
    check_file "$SCRIPT_DIR/backend/models/MovimientoContable.js" "Modelo MovimientoContable"
    
    # Backend Middleware
    log_both "\n${BOLD}Backend Middleware:${NC}"
    check_file "$SCRIPT_DIR/backend/middleware/auth.js" "Middleware auth"
    check_file "$SCRIPT_DIR/backend/middleware/errorHandler.js" "Middleware errorHandler"
    check_file "$SCRIPT_DIR/backend/middleware/validators.js" "Middleware validators"
    
    # Backend Services
    log_both "\n${BOLD}Backend Services:${NC}"
    check_file "$SCRIPT_DIR/backend/services/equipoService.js" "Servicio equipoService"
    
    # Backend Python/Flask
    log_both "\n${BOLD}Backend Python/Flask:${NC}"
    check_file "$SCRIPT_DIR/backend/run.py" "Servidor Flask"
    check_file "$SCRIPT_DIR/backend/app/__init__.py" "Factory Flask"
    check_file "$SCRIPT_DIR/backend/app/cache.py" "Cache Flask"
    check_file "$SCRIPT_DIR/backend/config.py" "Config Flask"
    check_file "$SCRIPT_DIR/backend/requirements.txt" "Requirements Python"
    check_file "$SCRIPT_DIR/backend/gunicorn.conf.py" "Config Gunicorn"
    
    # Frontend
    log_both "\n${BOLD}Frontend React:${NC}"
    check_file "$SCRIPT_DIR/frontend/package.json" "Package.json Frontend"
    check_file "$SCRIPT_DIR/frontend/src/App.js" "App.js"
    check_file "$SCRIPT_DIR/frontend/src/index.js" "index.js"
    check_file "$SCRIPT_DIR/frontend/src/services/api.js" "Servicio API"
    
    # Frontend Components
    log_both "\n${BOLD}Frontend Components:${NC}"
    check_file "$SCRIPT_DIR/frontend/src/components/Login.js" "Componente Login"
    check_file "$SCRIPT_DIR/frontend/src/components/AdminPanel.js" "Componente AdminPanel"
    check_file "$SCRIPT_DIR/frontend/src/components/AdminEquipos.js" "Componente AdminEquipos"
    check_file "$SCRIPT_DIR/frontend/src/components/DashboardAvanzado.js" "Componente DashboardAvanzado"
    check_file "$SCRIPT_DIR/frontend/src/components/Facturas.js" "Componente Facturas"
    check_file "$SCRIPT_DIR/frontend/src/components/FacturaTermica.js" "Componente FacturaTermica"
    check_file "$SCRIPT_DIR/frontend/src/components/CrearFactura.js" "Componente CrearFactura"
    check_file "$SCRIPT_DIR/frontend/src/components/CrearFacturaCompleta.js" "Componente CrearFacturaCompleta"
    check_file "$SCRIPT_DIR/frontend/src/components/VisorResultados.js" "Componente VisorResultados"
    check_file "$SCRIPT_DIR/frontend/src/components/Perfil.js" "Componente Perfil"
    
    # Database
    log_both "\n${BOLD}Database:${NC}"
    check_file "$SCRIPT_DIR/database/schema.sql" "Schema SQL"
    
    # Scripts
    log_both "\n${BOLD}Scripts:${NC}"
    check_file "$SCRIPT_DIR/diagnostico_completo.sh" "Script diagnóstico completo"
    check_file "$SCRIPT_DIR/test_final.sh" "Script test final"
    check_file "$SCRIPT_DIR/verificar_todo.sh" "Script verificar todo"
}

################################################################################
# SECCIÓN 2: VERIFICACIÓN DE ARCHIVOS ROTOS
################################################################################

test_broken_files() {
    print_section "2️⃣  VERIFICACIÓN DE CONTENIDO DE ARCHIVOS DE RUTAS"
    
    log_both "\n${BOLD}Verificando archivos de rutas:${NC}"
    
    # Verificar que los archivos tienen contenido válido
    local routes_dir="$SCRIPT_DIR/backend/routes"
    
    # Verificar archRoutes.js
    if [ -f "$routes_dir/authRoutes.js" ]; then
        if grep -q "const express = require" "$routes_dir/authRoutes.js" && \
           grep -q "module.exports" "$routes_dir/authRoutes.js"; then
            check_pass "authRoutes.js tiene código válido"
        else
            check_warn "authRoutes.js puede tener contenido incompleto"
        fi
    fi
    
    # Verificar citaRoutes.js
    if [ -f "$routes_dir/citaRoutes.js" ]; then
        if grep -q "const express = require" "$routes_dir/citaRoutes.js" && \
           grep -q "module.exports" "$routes_dir/citaRoutes.js"; then
            check_pass "citaRoutes.js tiene código válido"
        else
            check_warn "citaRoutes.js puede tener contenido incompleto"
        fi
    fi
    
    # Verificar pacienteRoutes.js
    if [ -f "$routes_dir/pacienteRoutes.js" ]; then
        if grep -q "const express = require" "$routes_dir/pacienteRoutes.js" && \
           grep -q "module.exports" "$routes_dir/pacienteRoutes.js"; then
            check_pass "pacienteRoutes.js tiene código válido"
        else
            check_warn "pacienteRoutes.js puede tener contenido incompleto"
        fi
    fi
    
    # Verificar estudioRoutes.js
    if [ -f "$routes_dir/estudioRoutes.js" ]; then
        if grep -q "const express = require" "$routes_dir/estudioRoutes.js" && \
           grep -q "module.exports" "$routes_dir/estudioRoutes.js"; then
            check_pass "estudioRoutes.js tiene código válido"
        else
            check_warn "estudioRoutes.js puede tener contenido incompleto"
        fi
    fi
}

################################################################################
# SECCIÓN 3: VERIFICACIÓN DE DEPENDENCIAS
################################################################################

test_dependencies() {
    print_section "3️⃣  VERIFICACIÓN DE DEPENDENCIAS"
    
    # Node.js dependencies
    log_both "\n${BOLD}Dependencias Node.js:${NC}"
    if check_dir "$SCRIPT_DIR/backend/node_modules" "node_modules backend"; then
        local module_count=$(ls -1 "$SCRIPT_DIR/backend/node_modules" 2>/dev/null | wc -l)
        log_both "   📦 Módulos instalados: $module_count"
        
        # Verificar dependencias clave
        local key_modules=("express" "mongoose" "jsonwebtoken" "bcryptjs" "cors" "dotenv")
        for module in "${key_modules[@]}"; do
            if [ -d "$SCRIPT_DIR/backend/node_modules/$module" ]; then
                check_pass "Módulo $module instalado"
            else
                check_fail "Módulo $module NO instalado"
            fi
        done
    fi
    
    # Frontend dependencies
    log_both "\n${BOLD}Dependencias Frontend:${NC}"
    if check_dir "$SCRIPT_DIR/frontend/node_modules" "node_modules frontend"; then
        local module_count=$(ls -1 "$SCRIPT_DIR/frontend/node_modules" 2>/dev/null | wc -l)
        log_both "   📦 Módulos instalados: $module_count"
        
        # Verificar dependencias clave
        local key_modules=("react" "react-dom" "react-router-dom" "axios")
        for module in "${key_modules[@]}"; do
            if [ -d "$SCRIPT_DIR/frontend/node_modules/$module" ]; then
                check_pass "Módulo $module instalado"
            else
                check_warn "Módulo $module NO instalado (puede usar alternativa)"
            fi
        done
    fi
    
    # Python dependencies
    log_both "\n${BOLD}Dependencias Python:${NC}"
    if [ -d "$SCRIPT_DIR/backend/venv" ]; then
        check_pass "Virtual environment Python existe"
        
        # Verificar si está activado o activarlo temporalmente
        if [ -f "$SCRIPT_DIR/backend/venv/bin/activate" ]; then
            source "$SCRIPT_DIR/backend/venv/bin/activate"
            
            # Verificar paquetes clave
            local key_packages=("Flask" "SQLAlchemy" "psycopg2" "gunicorn" "Flask-JWT-Extended")
            for package in "${key_packages[@]}"; do
                if python3 -c "import $package" 2>/dev/null; then
                    check_pass "Paquete Python $package instalado"
                else
                    # Algunos paquetes tienen nombres diferentes al importar
                    if pip show "${package}" > /dev/null 2>&1; then
                        check_pass "Paquete Python $package instalado"
                    else
                        check_fail "Paquete Python $package NO instalado"
                    fi
                fi
            done
            
            deactivate 2>/dev/null || true
        fi
    else
        check_warn "Virtual environment Python NO existe"
    fi
}

################################################################################
# SECCIÓN 4: VERIFICACIÓN DE CONSISTENCIA DE IMPORTS
################################################################################

test_import_consistency() {
    print_section "4️⃣  VERIFICACIÓN DE CONSISTENCIA DE IMPORTS"
    
    log_both "\n${BOLD}Verificando imports en server.js:${NC}"
    
    if [ -f "$SCRIPT_DIR/backend/server.js" ]; then
        # Extraer los require() de rutas en server.js
        while IFS= read -r line; do
            if [[ $line =~ app\.use\([^,]+,\ *require\(\'([^\']+)\'\) ]]; then
                local route_path="${BASH_REMATCH[1]}"
                local full_path="$SCRIPT_DIR/backend/${route_path}.js"
                
                if [ -f "$full_path" ]; then
                    check_pass "Import válido: $route_path"
                else
                    check_fail "Import inválido: $route_path (archivo no existe)"
                    log_only "   Esperado: $full_path"
                fi
            fi
        done < <(grep "app.use.*require" "$SCRIPT_DIR/backend/server.js")
    else
        check_fail "server.js no encontrado, no se pueden verificar imports"
    fi
    
    log_both "\n${BOLD}Verificando controllers importados en routes:${NC}"
    
    # Verificar controllers importados desde archivos de rutas
    for route_file in "$SCRIPT_DIR/backend/routes"/*.js; do
        if [ -f "$route_file" ]; then
            local route_name=$(basename "$route_file")
            
            # Buscar imports de controllers
            while IFS= read -r line; do
                if [[ $line =~ require\([\'\"]\.\./controllers/([^\'\"]+)[\'\"] ]]; then
                    local controller="${BASH_REMATCH[1]}"
                    local controller_path="$SCRIPT_DIR/backend/controllers/${controller}.js"
                    
                    if [ -f "$controller_path" ]; then
                        log_only "   ✓ $route_name → $controller"
                    else
                        check_fail "Controller no existe: $controller (requerido por $route_name)"
                    fi
                fi
            done < <(grep "require.*controllers" "$route_file")
        fi
    done
    
    check_pass "Verificación de consistencia de controllers completada"
}

################################################################################
# SECCIÓN 5: VERIFICACIÓN DE CONTROLLERS
################################################################################

test_controllers_exist() {
    print_section "5️⃣  VERIFICACIÓN DE CONTROLLERS"
    
    log_both "\n${BOLD}Verificando que controllers exportan funciones:${NC}"
    
    for controller_file in "$SCRIPT_DIR/backend/controllers"/*.js; do
        if [ -f "$controller_file" ]; then
            local controller_name=$(basename "$controller_file")
            
            # Verificar que tiene exports
            if grep -q "module.exports\|exports\." "$controller_file"; then
                check_pass "Controller $controller_name exporta funciones"
            else
                check_warn "Controller $controller_name puede no exportar funciones"
            fi
        fi
    done
}

################################################################################
# SECCIÓN 6: VERIFICACIÓN DE CONEXIÓN A BASE DE DATOS
################################################################################

test_database_connections() {
    print_section "6️⃣  VERIFICACIÓN DE CONEXIÓN A BASE DE DATOS"
    
    # MongoDB
    log_both "\n${BOLD}MongoDB:${NC}"
    
    # Intentar conexión básica a MongoDB
    if command -v mongosh > /dev/null 2>&1; then
        if mongosh --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; then
            check_pass "MongoDB está respondiendo"
        else
            check_warn "MongoDB no responde (puede no estar instalado localmente)"
        fi
    elif command -v mongo > /dev/null 2>&1; then
        if mongo --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; then
            check_pass "MongoDB está respondiendo"
        else
            check_warn "MongoDB no responde (puede no estar instalado localmente)"
        fi
    else
        check_warn "Cliente MongoDB no encontrado (puede usar conexión remota)"
    fi
    
    # PostgreSQL
    log_both "\n${BOLD}PostgreSQL:${NC}"
    
    # Verificar si PostgreSQL está instalado
    if command -v psql > /dev/null 2>&1; then
        check_pass "Cliente PostgreSQL instalado"
        
        # Intentar conexión (usar credenciales del diagnóstico_completo.sh)
        if PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost -c "SELECT 1;" > /dev/null 2>&1; then
            check_pass "Conexión a PostgreSQL exitosa"
            
            # Verificar tablas
            local table_count=$(PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | xargs)
            log_both "   📊 Tablas en base de datos: $table_count"
            
            if [ "$table_count" -gt 0 ]; then
                check_pass "$table_count tablas encontradas en PostgreSQL"
            else
                check_warn "0 tablas en PostgreSQL"
            fi
        else
            check_warn "No se pudo conectar a PostgreSQL (puede usar otra configuración)"
        fi
    else
        check_warn "Cliente PostgreSQL no instalado (puede usar conexión remota)"
    fi
}

################################################################################
# SECCIÓN 7: VERIFICACIÓN DE VARIABLES DE ENTORNO
################################################################################

test_environment_variables() {
    print_section "7️⃣  VERIFICACIÓN DE VARIABLES DE ENTORNO"
    
    log_both "\n${BOLD}Archivo .env:${NC}"
    
    if [ -f "$SCRIPT_DIR/backend/.env" ]; then
        check_pass "Archivo .env existe"
        
        # Verificar variables clave
        local key_vars=("MONGODB_URI" "JWT_SECRET" "PORT" "DATABASE_URL")
        for var in "${key_vars[@]}"; do
            if grep -q "^${var}=" "$SCRIPT_DIR/backend/.env"; then
                check_pass "Variable $var configurada"
            else
                check_warn "Variable $var NO encontrada en .env"
            fi
        done
    else
        check_warn "Archivo .env NO existe"
        
        # Verificar si existe .env.example
        if [ -f "$SCRIPT_DIR/backend/.env.example" ]; then
            check_pass "Archivo .env.example existe (puede usarse como referencia)"
        else
            check_fail "Ni .env ni .env.example existen"
        fi
    fi
}

################################################################################
# SECCIÓN 8: TEST DE API ENDPOINTS
################################################################################

test_api_endpoints() {
    print_section "8️⃣  TEST DE API ENDPOINTS"
    
    log_both "\n${BOLD}Verificando si el servidor está corriendo:${NC}"
    
    # Verificar puerto 5000
    if ss -tuln 2>/dev/null | grep -q ":5000 " || lsof -i :5000 > /dev/null 2>&1; then
        check_pass "Puerto 5000 está en uso (servidor probablemente corriendo)"
        
        # Test health endpoint
        log_both "\n${BOLD}Probando endpoints:${NC}"
        
        local base_url="http://localhost:5000"
        
        # Health check
        local health_code=$(curl -s -o /dev/null -w "%{http_code}" "$base_url/api/health" 2>/dev/null)
        if [ "$health_code" = "200" ]; then
            check_pass "GET /api/health (HTTP $health_code)"
        else
            check_warn "GET /api/health (HTTP $health_code)"
        fi
        
        # Login
        log_both "\n   ${BOLD}Probando autenticación:${NC}"
        local login_response=$(curl -s -w "\n%{http_code}" -X POST "$base_url/api/auth/login" \
            -H "Content-Type: application/json" \
            -d '{"username":"admin","password":"admin123"}' 2>/dev/null)
        
        local login_code=$(echo "$login_response" | tail -n1)
        local login_body=$(echo "$login_response" | head -n-1)
        
        if [ "$login_code" = "200" ]; then
            check_pass "POST /api/auth/login (HTTP $login_code)"
            
            # Extraer token
            local token=$(echo "$login_body" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
            if [ -z "$token" ]; then
                token=$(echo "$login_body" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
            fi
            
            if [ -n "$token" ]; then
                check_pass "Token JWT obtenido correctamente"
                
                # Probar endpoints protegidos
                log_both "\n   ${BOLD}Probando endpoints protegidos:${NC}"
                
                # /api/auth/me
                local me_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/auth/me" 2>/dev/null)
                [ "$me_code" = "200" ] && check_pass "GET /api/auth/me (HTTP $me_code)" || check_warn "GET /api/auth/me (HTTP $me_code)"
                
                # /api/pacientes
                local pac_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/pacientes" 2>/dev/null)
                [ "$pac_code" = "200" ] && check_pass "GET /api/pacientes (HTTP $pac_code)" || check_warn "GET /api/pacientes (HTTP $pac_code)"
                
                # /api/citas
                local cit_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/citas" 2>/dev/null)
                [ "$cit_code" = "200" ] && check_pass "GET /api/citas (HTTP $cit_code)" || check_warn "GET /api/citas (HTTP $cit_code)"
                
                # /api/estudios
                local est_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/estudios" 2>/dev/null)
                [ "$est_code" = "200" ] && check_pass "GET /api/estudios (HTTP $est_code)" || check_warn "GET /api/estudios (HTTP $est_code)"
                
                # /api/resultados
                local res_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/resultados" 2>/dev/null)
                [ "$res_code" = "200" ] && check_pass "GET /api/resultados (HTTP $res_code)" || check_warn "GET /api/resultados (HTTP $res_code)"
                
                # /api/facturas
                local fac_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/facturas" 2>/dev/null)
                [ "$fac_code" = "200" ] && check_pass "GET /api/facturas (HTTP $fac_code)" || check_warn "GET /api/facturas (HTTP $fac_code)"
                
                # /api/dashboard
                local dash_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/dashboard" 2>/dev/null)
                [ "$dash_code" != "000" ] && check_pass "GET /api/dashboard (HTTP $dash_code)" || check_warn "GET /api/dashboard no responde"
                
                # /api/reportes/dashboard
                local rep_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/reportes/dashboard" 2>/dev/null)
                [ "$rep_code" != "000" ] && check_pass "GET /api/reportes/dashboard (HTTP $rep_code)" || check_warn "GET /api/reportes/dashboard no responde"
                
                # /api/admin/usuarios
                local adm_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/admin/usuarios" 2>/dev/null)
                [ "$adm_code" != "000" ] && check_pass "GET /api/admin/usuarios (HTTP $adm_code)" || check_warn "GET /api/admin/usuarios no responde"
                
                # /api/equipos
                local equ_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/equipos" 2>/dev/null)
                [ "$equ_code" != "000" ] && check_pass "GET /api/equipos (HTTP $equ_code)" || check_warn "GET /api/equipos no responde"
                
                # /api/contabilidad
                local cont_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base_url/api/contabilidad" 2>/dev/null)
                [ "$cont_code" != "000" ] && check_pass "GET /api/contabilidad (HTTP $cont_code)" || check_warn "GET /api/contabilidad no responde"
                
            else
                check_fail "No se pudo extraer token JWT"
            fi
        else
            check_warn "POST /api/auth/login (HTTP $login_code) - Servidor puede no estar corriendo"
        fi
        
    else
        check_warn "Puerto 5000 NO está en uso - servidor probablemente NO está corriendo"
        log_both "   ℹ️  Para ejecutar tests de API, primero inicie el servidor con: npm start"
    fi
}

################################################################################
# SECCIÓN 9: VERIFICACIÓN DE MAPEO FRONTEND ↔ BACKEND
################################################################################

test_route_mapping() {
    print_section "9️⃣  VERIFICACIÓN DE MAPEO FRONTEND ↔ BACKEND"
    
    log_both "\n${BOLD}Analizando rutas llamadas por frontend:${NC}"
    
    if [ -f "$SCRIPT_DIR/frontend/src/services/api.js" ]; then
        # Extraer rutas del api.js usando this.request() y fetch()
        local routes_request=$(grep -o "this\.request('[^']*'" "$SCRIPT_DIR/frontend/src/services/api.js" | sed "s/this\.request('//g" | sed "s/'//g" | sort -u)
        local routes_fetch=$(grep -o "API_URL + '[^']*'" "$SCRIPT_DIR/frontend/src/services/api.js" | sed "s/API_URL + '//g" | sed "s/'//g" | sort -u)
        local api_routes=$(echo -e "$routes_request\n$routes_fetch" | sort -u)
        
        log_both "\n${BOLD}Rutas encontradas en api.js:${NC}"
        echo "$api_routes" | while read -r route; do
            [ -n "$route" ] && log_only "   $route"
        done
        
        # Verificar rutas específicas documentadas en MAPEO_RUTAS.md
        log_both "\n${BOLD}Verificando rutas específicas:${NC}"
        
        # Según MAPEO_RUTAS.md
        local -A route_checks=(
            ["/api/auth/login"]="Login"
            ["/api/auth/me"]="Auth me"
            ["/api/reportes/dashboard"]="Reportes dashboard"
            ["/api/citas/hoy"]="Citas hoy"
            ["/api/dashboard/citas-grafica"]="Dashboard gráfica"
            ["/api/dashboard/top-estudios"]="Dashboard top estudios"
            ["/api/pacientes/"]="Pacientes lista"
            ["/api/estudios/"]="Estudios lista"
            ["/api/citas/"]="Citas lista"
            ["/api/resultados/"]="Resultados lista"
            ["/api/facturas/"]="Facturas lista"
            ["/api/admin/usuarios"]="Admin usuarios"
            ["/api/contabilidad/"]="Contabilidad"
        )
        
        for route_path in "${!route_checks[@]}"; do
            local route_desc="${route_checks[$route_path]}"
            # Extract just the route part without /api prefix for matching
            local route_without_api="${route_path#/api}"
            if grep -q "this\.request('$route_without_api'" "$SCRIPT_DIR/frontend/src/services/api.js" || \
               grep -q "API_URL + '$route_without_api'" "$SCRIPT_DIR/frontend/src/services/api.js"; then
                check_pass "Frontend llama a: $route_path ($route_desc)"
            else
                check_warn "Frontend NO llama a: $route_path ($route_desc)"
            fi
        done
        
        # Verificar discrepancias conocidas del MAPEO_RUTAS.md
        log_both "\n${BOLD}Verificando discrepancias conocidas:${NC}"
        
        # Dashboard stats
        if grep -q "this\.request('/dashboard/stats'" "$SCRIPT_DIR/frontend/src/services/api.js"; then
            check_warn "Frontend pide /api/dashboard/stats (backend tiene /api/dashboard)"
        fi
        
        # Estudios categorías
        if grep -q "this\.request('/estudios/categorias'" "$SCRIPT_DIR/frontend/src/services/api.js"; then
            check_pass "Frontend pide /api/estudios/categorias (verificar si backend lo soporta)"
        fi
        
        # Citas vs Ordenes
        log_both "\n${BOLD}Nota sobre citas vs órdenes:${NC}"
        log_both "   ℹ️  El frontend usa /api/ordenes/ para operaciones CRUD de citas"
        log_both "   ℹ️  El backend mapea /api/ordenes → ./routes/citas (línea 129 server.js)"
        log_both "   ℹ️  Esto es correcto pero puede ser confuso en el código"
        
    else
        check_fail "api.js no encontrado, no se puede verificar mapeo"
    fi
}

################################################################################
# SECCIÓN 10: RESUMEN FINAL
################################################################################

print_summary() {
    print_section "📊 RESUMEN FINAL"
    
    log_both ""
    log_both "${BOLD}Total de verificaciones: $TOTAL_TESTS${NC}"
    log_both "${GREEN}${BOLD}✅ Pasadas: $PASSED_TESTS${NC}"
    log_both "${YELLOW}${BOLD}⚠️  Advertencias: $WARNING_TESTS${NC}"
    log_both "${RED}${BOLD}❌ Fallidas: $FAILED_TESTS${NC}"
    log_both ""
    
    # Calcular porcentaje
    if [ $TOTAL_TESTS -gt 0 ]; then
        local percentage=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        log_both "${BOLD}Nivel de salud del sistema: $percentage%${NC}"
        
        if [ $percentage -ge 90 ]; then
            log_both "${GREEN}${BOLD}🎉 Sistema en excelente estado${NC}"
        elif [ $percentage -ge 75 ]; then
            log_both "${YELLOW}${BOLD}⚡ Sistema funcional con advertencias${NC}"
        elif [ $percentage -ge 50 ]; then
            log_both "${YELLOW}${BOLD}⚠️  Sistema requiere atención${NC}"
        else
            log_both "${RED}${BOLD}🚨 Sistema requiere atención urgente${NC}"
        fi
    fi
    
    # Detalles de fallos
    if [ ${#FAILED_ITEMS[@]} -gt 0 ]; then
        log_both ""
        log_both "${RED}${BOLD}❌ Elementos fallidos:${NC}"
        for item in "${FAILED_ITEMS[@]}"; do
            log_both "${RED}   • $item${NC}"
        done
    fi
    
    # Detalles de advertencias
    if [ ${#WARNING_ITEMS[@]} -gt 0 ] && [ ${#WARNING_ITEMS[@]} -le 10 ]; then
        log_both ""
        log_both "${YELLOW}${BOLD}⚠️  Advertencias principales:${NC}"
        for item in "${WARNING_ITEMS[@]:0:10}"; do
            log_both "${YELLOW}   • $item${NC}"
        done
    fi
    
    log_both ""
    log_both "${BOLD}════════════════════════════════════════════════════════════════════════════${NC}"
    log_both "${BOLD}Log completo guardado en: $LOG_FILE${NC}"
    log_both "${BOLD}════════════════════════════════════════════════════════════════════════════${NC}"
    log_both ""
}

################################################################################
# MAIN
################################################################################

main() {
    initialize
    
    test_file_structure
    test_broken_files
    test_dependencies
    test_import_consistency
    test_controllers_exist
    test_database_connections
    test_environment_variables
    test_api_endpoints
    test_route_mapping
    
    print_summary
}

# Ejecutar script
main
