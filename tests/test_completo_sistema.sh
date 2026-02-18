#!/bin/bash

# ====================================================================
# Script de Test Completo del Sistema - Centro Diagnóstico Mi Esperanza
# ====================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Configurar archivo de log con timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/test_completo_${TIMESTAMP}.log"

# Crear directorio de logs si no existe
mkdir -p "${LOG_DIR}"

# Función para log
log() {
    echo -e "$1" | tee -a "${LOG_FILE}"
}

# Función para test exitoso
test_pass() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log "${GREEN}✅ PASS${NC}: $1"
}

# Función para test fallido
test_fail() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    FAILED_TESTS=$((FAILED_TESTS + 1))
    log "${RED}❌ FAIL${NC}: $1"
}

# Función para sección
section() {
    log "\n${BLUE}========================================${NC}"
    log "${BLUE}$1${NC}"
    log "${BLUE}========================================${NC}"
}

# Función para verificar archivo
check_file() {
    local file=$1
    local description=$2
    if [ -f "$file" ]; then
        test_pass "Archivo existe: $description ($file)"
        return 0
    else
        test_fail "Archivo NO existe: $description ($file)"
        return 1
    fi
}

# Función para verificar directorio
check_dir() {
    local dir=$1
    local description=$2
    if [ -d "$dir" ]; then
        test_pass "Directorio existe: $description ($dir)"
        return 0
    else
        test_fail "Directorio NO existe: $description ($dir)"
        return 1
    fi
}

# Función para verificar import/require en archivo
check_import() {
    local file=$1
    local pattern=$2
    local description=$3
    if [ -f "$file" ]; then
        if grep -q "$pattern" "$file" 2>/dev/null; then
            test_pass "Import correcto: $description en $file"
            return 0
        else
            test_fail "Import NO encontrado: $description en $file (pattern: $pattern)"
            return 1
        fi
    else
        test_fail "Archivo no existe para verificar import: $file"
        return 1
    fi
}

# Función para verificar export en archivo
check_export() {
    local file=$1
    local pattern=$2
    local description=$3
    if [ -f "$file" ]; then
        if grep -q "$pattern" "$file" 2>/dev/null; then
            test_pass "Export correcto: $description en $file"
            return 0
        else
            test_fail "Export NO encontrado: $description en $file"
            return 1
        fi
    else
        test_fail "Archivo no existe para verificar export: $file"
        return 1
    fi
}

# Inicio del script
log "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
log "${YELLOW}║  CENTRO DIAGNÓSTICO MI ESPERANZA v5                       ║${NC}"
log "${YELLOW}║  Test Completo del Sistema                                ║${NC}"
log "${YELLOW}║  Fecha: $(date +'%Y-%m-%d %H:%M:%S')                          ║${NC}"
log "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"

# ====================================================================
# 1. VERIFICACIÓN DE ESTRUCTURA DEL PROYECTO
# ====================================================================
section "1. ESTRUCTURA DEL PROYECTO"

check_dir "backend" "Backend principal"
check_dir "frontend" "Frontend React"
check_dir "backend/config" "Configuración backend"
check_dir "backend/controllers" "Controladores"
check_dir "backend/middleware" "Middleware"
check_dir "backend/models" "Modelos MongoDB"
check_dir "backend/routes" "Rutas API"
check_dir "backend/services" "Servicios"
check_dir "backend/app" "Backend Python/Flask"
check_dir "frontend/src" "Código fuente frontend"
check_dir "frontend/src/components" "Componentes React"
check_dir "frontend/public" "Archivos públicos frontend"
check_dir "database" "Scripts de base de datos"
check_dir "logs" "Directorio de logs"

# ====================================================================
# 2. VERIFICACIÓN DE ARCHIVOS CLAVE DEL BACKEND NODE.JS
# ====================================================================
section "2. ARCHIVOS CLAVE BACKEND NODE.JS"

# Archivo principal
check_file "backend/server.js" "Servidor principal Node.js"
check_file "backend/package.json" "Dependencias Node.js"
check_file "backend/package-lock.json" "Lock de dependencias Node.js"

# Configuración
check_file "backend/config/db.js" "Configuración MongoDB"

# Middleware
check_file "backend/middleware/auth.js" "Middleware de autenticación"
check_file "backend/middleware/errorHandler.js" "Middleware de manejo de errores"
check_file "backend/middleware/validators.js" "Middleware de validaciones"

# Modelos
check_file "backend/models/User.js" "Modelo User"
check_file "backend/models/Paciente.js" "Modelo Paciente"
check_file "backend/models/Cita.js" "Modelo Cita"
check_file "backend/models/Estudio.js" "Modelo Estudio"
check_file "backend/models/Resultado.js" "Modelo Resultado"
check_file "backend/models/Factura.js" "Modelo Factura"
check_file "backend/models/Equipo.js" "Modelo Equipo"
check_file "backend/models/MovimientoContable.js" "Modelo MovimientoContable"

# Rutas
check_file "backend/routes/auth.js" "Rutas de autenticación"
check_file "backend/routes/pacientes.js" "Rutas de pacientes"
check_file "backend/routes/citas.js" "Rutas de citas"
check_file "backend/routes/estudios.js" "Rutas de estudios"
check_file "backend/routes/resultados.js" "Rutas de resultados"
check_file "backend/routes/facturas.js" "Rutas de facturas"
check_file "backend/routes/dashboard.js" "Rutas de dashboard"
check_file "backend/routes/admin.js" "Rutas de admin"
check_file "backend/routes/equipoRoutes.js" "Rutas de equipos"
check_file "backend/routes/contabilidad.js" "Rutas de contabilidad"

# Controladores
check_file "backend/controllers/authController.js" "Controlador de autenticación"
check_file "backend/controllers/pacienteController.js" "Controlador de pacientes"
check_file "backend/controllers/citaController.js" "Controlador de citas"
check_file "backend/controllers/estudioController.js" "Controlador de estudios"
check_file "backend/controllers/resultadoController.js" "Controlador de resultados"
check_file "backend/controllers/facturaController.js" "Controlador de facturas"
check_file "backend/controllers/dashboardController.js" "Controlador de dashboard"
check_file "backend/controllers/adminController.js" "Controlador de admin"
check_file "backend/controllers/equipoController.js" "Controlador de equipos"
check_file "backend/controllers/contabilidadController.js" "Controlador de contabilidad"

# Servicios
check_file "backend/services/equipoService.js" "Servicio de equipos"

# ====================================================================
# 3. VERIFICACIÓN DE ARCHIVOS BACKEND PYTHON/FLASK
# ====================================================================
section "3. ARCHIVOS BACKEND PYTHON/FLASK"

check_file "backend/config.py" "Configuración Python/Flask"
check_file "backend/run.py" "Servidor Flask"
check_file "backend/requirements.txt" "Dependencias Python"
check_file "backend/app/__init__.py" "Inicialización app Flask"
check_file "backend/app/cache.py" "Cache Flask"

# ====================================================================
# 4. VERIFICACIÓN DE ARCHIVOS FRONTEND REACT
# ====================================================================
section "4. ARCHIVOS FRONTEND REACT"

check_file "frontend/package.json" "Dependencias React"
check_file "frontend/package-lock.json" "Lock de dependencias React"
check_file "frontend/src/index.js" "Punto de entrada React"
check_file "frontend/src/App.js" "Componente principal App"
check_file "frontend/src/App.css" "Estilos App"
check_file "frontend/src/services/api.js" "Servicio API"

# Componentes principales
check_file "frontend/src/components/Login.js" "Componente Login"
check_file "frontend/src/components/Dashboard.js" "Componente Dashboard"
check_file "frontend/src/components/AdminPanel.js" "Componente AdminPanel"
check_file "frontend/src/components/AdminEquipos.js" "Componente AdminEquipos"
check_file "frontend/src/components/DashboardAvanzado.js" "Componente DashboardAvanzado"
check_file "frontend/src/components/Facturas.js" "Componente Facturas"
check_file "frontend/src/components/FacturaTermica.js" "Componente FacturaTermica"
check_file "frontend/src/components/VisorResultados.js" "Componente VisorResultados"
check_file "frontend/src/components/Perfil.js" "Componente Perfil"
check_file "frontend/src/components/CrearFactura.js" "Componente CrearFactura"
check_file "frontend/src/components/CrearFacturaCompleta.js" "Componente CrearFacturaCompleta"
check_file "frontend/src/components/ConsultaRapida.js" "Componente ConsultaRapida"
check_file "frontend/src/theme.js" "Theme configuración"

# ====================================================================
# 5. VERIFICACIÓN DE IMPORTS/REQUIRES EN BACKEND
# ====================================================================
section "5. VERIFICACIÓN DE IMPORTS/REQUIRES EN BACKEND"

# server.js imports
check_import "backend/server.js" "require('./config/db')" "Importa config/db"
check_import "backend/server.js" "require('./middleware/errorHandler')" "Importa errorHandler"
check_import "backend/server.js" "require('./routes/auth')" "Importa routes/auth"
check_import "backend/server.js" "require('./routes/pacientes')" "Importa routes/pacientes"
check_import "backend/server.js" "require('./routes/citas')" "Importa routes/citas"
check_import "backend/server.js" "require('./routes/estudios')" "Importa routes/estudios"
check_import "backend/server.js" "require('./routes/resultados')" "Importa routes/resultados"
check_import "backend/server.js" "require('./routes/facturas')" "Importa routes/facturas"
check_import "backend/server.js" "require('./routes/dashboard')" "Importa routes/dashboard"
check_import "backend/server.js" "require('./routes/admin')" "Importa routes/admin"
check_import "backend/server.js" "require('./routes/equipoRoutes')" "Importa routes/equipoRoutes"
check_import "backend/server.js" "require('./routes/contabilidad')" "Importa routes/contabilidad"
check_import "backend/server.js" "require('./services/equipoService')" "Importa equipoService"

# Middleware imports
check_import "backend/middleware/auth.js" "require('../models/User')" "auth.js importa User"

# Routes imports
check_import "backend/routes/auth.js" "../controllers/authController" "auth.js importa authController"
check_import "backend/routes/auth.js" "../middleware/auth" "auth.js importa middleware auth"
check_import "backend/routes/admin.js" "../controllers/adminController" "admin.js importa adminController"
check_import "backend/routes/dashboard.js" "../controllers/dashboardController" "dashboard.js importa dashboardController"
check_import "backend/routes/contabilidad.js" "../controllers/contabilidadController" "contabilidad.js importa contabilidadController"
check_import "backend/routes/equipoRoutes.js" "../controllers/equipoController" "equipoRoutes.js importa equipoController"

# Services imports
check_import "backend/services/equipoService.js" "../models/Equipo" "equipoService.js importa Equipo"

# ====================================================================
# 6. VERIFICACIÓN DE EXPORTS EN MIDDLEWARE
# ====================================================================
section "6. VERIFICACIÓN DE EXPORTS EN MIDDLEWARE"

check_export "backend/middleware/errorHandler.js" "module.exports.*errorHandler" "errorHandler exporta errorHandler"
check_export "backend/middleware/errorHandler.js" "module.exports.*notFound" "errorHandler exporta notFound"

# ====================================================================
# 7. VERIFICACIÓN DE IMPORTS EN FRONTEND
# ====================================================================
section "7. VERIFICACIÓN DE IMPORTS EN FRONTEND"

# App.js imports
check_import "frontend/src/App.js" "from.*Login" "App.js importa Login"
check_import "frontend/src/App.js" "from.*Dashboard" "App.js importa Dashboard"
check_import "frontend/src/App.js" "from.*AdminPanel" "App.js importa AdminPanel"

# Login imports
check_import "frontend/src/components/Login.js" "from.*api" "Login.js importa api service"

# Facturas imports
check_import "frontend/src/components/Facturas.js" "from.*FacturaTermica" "Facturas.js importa FacturaTermica"

# FacturaTermica imports
check_import "frontend/src/components/FacturaTermica.js" "from.*react-barcode" "FacturaTermica.js importa react-barcode"

# ====================================================================
# 8. VERIFICACIÓN DE DEPENDENCIAS
# ====================================================================
section "8. VERIFICACIÓN DE DEPENDENCIAS"

# Verificar que package.json backend tiene las dependencias clave
if [ -f "backend/package.json" ]; then
    if grep -q "\"express\"" backend/package.json; then
        test_pass "Backend: Dependencia 'express' encontrada"
    else
        test_fail "Backend: Dependencia 'express' NO encontrada"
    fi
    
    if grep -q "\"mongoose\"" backend/package.json; then
        test_pass "Backend: Dependencia 'mongoose' encontrada"
    else
        test_fail "Backend: Dependencia 'mongoose' NO encontrada"
    fi
    
    if grep -q "\"cors\"" backend/package.json; then
        test_pass "Backend: Dependencia 'cors' encontrada"
    else
        test_fail "Backend: Dependencia 'cors' NO encontrada"
    fi
fi

# Verificar que package.json frontend tiene las dependencias clave
if [ -f "frontend/package.json" ]; then
    if grep -q "\"react\"" frontend/package.json; then
        test_pass "Frontend: Dependencia 'react' encontrada"
    else
        test_fail "Frontend: Dependencia 'react' NO encontrada"
    fi
    
    if grep -q "\"axios\"" frontend/package.json; then
        test_pass "Frontend: Dependencia 'axios' encontrada"
    else
        test_fail "Frontend: Dependencia 'axios' NO encontrada"
    fi
    
    if grep -q "\"react-router-dom\"" frontend/package.json; then
        test_pass "Frontend: Dependencia 'react-router-dom' encontrada"
    else
        test_fail "Frontend: Dependencia 'react-router-dom' NO encontrada"
    fi
    
    if grep -q "\"react-icons\"" frontend/package.json; then
        test_pass "Frontend: Dependencia 'react-icons' encontrada"
    else
        test_fail "Frontend: Dependencia 'react-icons' NO encontrada"
    fi
    
    if grep -q "\"react-barcode\"" frontend/package.json; then
        test_pass "Frontend: Dependencia 'react-barcode' encontrada"
    else
        test_fail "Frontend: Dependencia 'react-barcode' NO encontrada"
    fi
fi

# Verificar requirements.txt Python
if [ -f "backend/requirements.txt" ]; then
    if grep -q "Flask" backend/requirements.txt; then
        test_pass "Python: Dependencia 'Flask' encontrada"
    else
        test_fail "Python: Dependencia 'Flask' NO encontrada"
    fi
fi

# ====================================================================
# 9. VERIFICACIÓN DE SHELL SCRIPTS
# ====================================================================
section "9. VERIFICACIÓN DE SHELL SCRIPTS"

check_file "auditoria_sistema.sh" "Script de auditoría"
check_file "backup_db.sh" "Script de backup DB"
check_file "diagnostico.sh" "Script de diagnóstico"
check_file "diagnostico_completo.sh" "Script de diagnóstico completo"
check_file "generar_analisis_falsos.sh" "Script de análisis falsos"
check_file "monitor.sh" "Script de monitoreo"
check_file "run_production.sh" "Script de producción"
check_file "setup.sh" "Script de setup"
check_file "setup_final.sh" "Script de setup final"
check_file "start-all.sh" "Script de inicio completo"
check_file "start-backend.sh" "Script de inicio backend"
check_file "start-frontend.sh" "Script de inicio frontend"
check_file "test_final.sh" "Script de test final"
check_file "verificar_todo.sh" "Script de verificación"

# ====================================================================
# 10. VERIFICACIÓN DE DATABASE
# ====================================================================
section "10. VERIFICACIÓN DE BASE DE DATOS"

check_file "database/schema.sql" "Schema de base de datos"

# ====================================================================
# 11. VERIFICACIÓN DE RUTAS FRONTEND → BACKEND
# ====================================================================
section "11. VERIFICACIÓN DE MAPEO DE RUTAS"

# Verificar que los endpoints existen en los componentes frontend
log "\n${YELLOW}Frontend → Backend Route Mapping:${NC}"

# Dashboard
if grep -q "/api/dashboard" frontend/src/components/Dashboard.js 2>/dev/null || \
   grep -q "/api/dashboard" frontend/src/components/DashboardAvanzado.js 2>/dev/null || \
   grep -q "/api/dashboard" frontend/src/services/api.js 2>/dev/null; then
    test_pass "Frontend usa /api/dashboard"
else
    test_fail "Frontend NO usa /api/dashboard"
fi

# Estudios
if grep -q "/api/estudios" frontend/src/components/*.js 2>/dev/null || \
   grep -q "/api/estudios" frontend/src/services/api.js 2>/dev/null; then
    test_pass "Frontend usa /api/estudios"
else
    test_fail "Frontend NO usa /api/estudios"
fi

# Pacientes
if grep -q "/api/pacientes" frontend/src/components/*.js 2>/dev/null || \
   grep -q "/api/pacientes" frontend/src/services/api.js 2>/dev/null; then
    test_pass "Frontend usa /api/pacientes"
else
    test_fail "Frontend NO usa /api/pacientes"
fi

# Citas
if grep -q "/api/citas" frontend/src/components/*.js 2>/dev/null || \
   grep -q "/api/citas" frontend/src/services/api.js 2>/dev/null; then
    test_pass "Frontend usa /api/citas"
else
    test_fail "Frontend NO usa /api/citas"
fi

# Equipos
if grep -q "/api/equipos" frontend/src/components/AdminEquipos.js 2>/dev/null; then
    test_pass "Frontend usa /api/equipos en AdminEquipos"
else
    test_fail "Frontend NO usa /api/equipos"
fi

# Admin usuarios
if grep -q "/api/admin/usuarios" frontend/src/components/AdminPanel.js 2>/dev/null || \
   grep -q "/api/admin/usuarios" frontend/src/components/AdminUsuarios.js 2>/dev/null || \
   grep -q "/api/admin/usuarios" frontend/src/services/api.js 2>/dev/null; then
    test_pass "Frontend usa /api/admin/usuarios"
else
    test_fail "Frontend NO usa /api/admin/usuarios"
fi

# Resultados
if grep -q "/api/resultados" frontend/src/components/VisorResultados.js 2>/dev/null || \
   grep -q "/api/resultados" frontend/src/components/Resultados.js 2>/dev/null || \
   grep -q "/api/resultados" frontend/src/services/api.js 2>/dev/null; then
    test_pass "Frontend usa /api/resultados"
else
    test_fail "Frontend NO usa /api/resultados"
fi

# ====================================================================
# 12. VERIFICACIÓN DE CONEXIÓN A BASE DE DATOS (SINTAXIS)
# ====================================================================
section "12. VERIFICACIÓN DE CONFIGURACIÓN DE BASE DE DATOS"

if [ -f "backend/config/db.js" ]; then
    if grep -q "mongoose.connect" backend/config/db.js; then
        test_pass "db.js tiene llamada a mongoose.connect"
    else
        test_fail "db.js NO tiene llamada a mongoose.connect"
    fi
    
    if grep -q "module.exports" backend/config/db.js; then
        test_pass "db.js exporta función de conexión"
    else
        test_fail "db.js NO exporta función de conexión"
    fi
fi

# ====================================================================
# 13. VERIFICACIÓN DE MODELOS MONGODB
# ====================================================================
section "13. VERIFICACIÓN DE MODELOS MONGODB"

# Verificar que cada modelo exporta correctamente
models=("User" "Paciente" "Cita" "Estudio" "Resultado" "Factura" "Equipo" "MovimientoContable")

for model in "${models[@]}"; do
    file="backend/models/${model}.js"
    if [ -f "$file" ]; then
        if grep -q "module.exports.*mongoose.model" "$file"; then
            test_pass "Modelo $model exporta correctamente"
        else
            test_fail "Modelo $model NO exporta correctamente"
        fi
        
        if grep -q "Schema" "$file"; then
            test_pass "Modelo $model define Schema"
        else
            test_fail "Modelo $model NO define Schema"
        fi
    fi
done

# ====================================================================
# 14. VERIFICACIÓN DE CONFIGURACIÓN
# ====================================================================
section "14. VERIFICACIÓN DE ARCHIVOS DE CONFIGURACIÓN"

check_file ".gitignore" "Archivo .gitignore"
check_file "README.md" "Archivo README"
check_file "MAPEO_RUTAS.md" "Documentación de mapeo de rutas"

# ====================================================================
# RESUMEN FINAL
# ====================================================================
log "\n${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
log "${YELLOW}║                   RESUMEN DE TESTS                        ║${NC}"
log "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
log ""
log "${BLUE}Total de tests ejecutados:${NC} $TOTAL_TESTS"
log "${GREEN}Tests exitosos:${NC} $PASSED_TESTS"
log "${RED}Tests fallidos:${NC} $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    log "\n${GREEN}✅ TODOS LOS TESTS PASARON EXITOSAMENTE${NC}"
    log "${GREEN}✨ Sistema verificado correctamente ✨${NC}"
else
    log "\n${RED}❌ ALGUNOS TESTS FALLARON${NC}"
    log "${YELLOW}⚠️  Por favor revisa el log para más detalles${NC}"
fi

PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
log "\n${BLUE}Tasa de éxito:${NC} ${PERCENTAGE}%"
log "\n${BLUE}Log guardado en:${NC} ${LOG_FILE}"
log ""

# Retornar código de salida basado en tests fallidos
if [ $FAILED_TESTS -eq 0 ]; then
    exit 0
else
    exit 1
fi
