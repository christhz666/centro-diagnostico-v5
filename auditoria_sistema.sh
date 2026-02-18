#!/bin/bash

echo "=========================================="
echo "AUDITORÍA DEL SISTEMA - CENTRO DIAGNÓSTICO"
echo "=========================================="
echo ""

# 1. Tamaño del proyecto
echo "?? TAMAÑO DEL PROYECTO:"
du -sh backend/ frontend/ database/ 2>/dev/null
echo ""

# 2. Archivos de código
echo "?? ARCHIVOS DE CÓDIGO:"
echo "Backend (Python):"
find backend/ -name "*.py" 2>/dev/null | wc -l
echo "Frontend (JavaScript):"
find frontend/src -name "*.js" -o -name "*.jsx" 2>/dev/null | wc -l
echo ""

# 3. Base de datos
echo "??? BASE DE DATOS:"
PGPASSWORD='CentroDiag2025!Seguro' psql -U centro_user -h localhost -d centro_diagnostico << 'ENDSQL'
SELECT 
    tablename as "Tabla",
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS "Tamaño"
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

SELECT 'Pacientes' as tabla, COUNT(*) as registros FROM pacientes
UNION ALL SELECT 'Órdenes', COUNT(*) FROM ordenes
UNION ALL SELECT 'Facturas', COUNT(*) FROM facturas
UNION ALL SELECT 'Usuarios', COUNT(*) FROM usuarios
UNION ALL SELECT 'Estudios', COUNT(*) FROM estudios;
ENDSQL

# 4. Estado de servicios
echo ""
echo "?? SERVICIOS:"
systemctl is-active centro-backend && echo "? Backend: Activo" || echo "? Backend: Inactivo"
systemctl is-active centro-frontend && echo "? Frontend: Activo" || echo "? Frontend: Inactivo"
systemctl is-active postgresql && echo "? PostgreSQL: Activo" || echo "? PostgreSQL: Inactivo"

# 5. Uso de recursos
echo ""
echo "?? USO DE RECURSOS:"
echo "CPU:"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "Uso: " 100 - $1"%"}'
echo "Memoria:"
free -h | awk '/^Mem:/ {print "Usado: " $3 " / Total: " $2}'
echo "Disco:"
df -h / | awk 'NR==2 {print "Usado: " $3 " / Total: " $2 " (" $5 ")"}'

echo ""
echo "=========================================="
