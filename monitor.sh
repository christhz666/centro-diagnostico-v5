#!/bin/bash
# Monitor de salud del sistema
echo "============================================"
echo "  CENTRO DIAGNÓSTICO - MONITOR"
echo "  $(date)"
echo "============================================"
echo ""

# Backend
if systemctl is-active --quiet centro-backend; then
    echo "? Backend: ACTIVO"
else
    echo "? Backend: CAÍDO - Reiniciando..."
    sudo systemctl restart centro-backend
fi

# Nginx
if systemctl is-active --quiet nginx; then
    echo "? Nginx: ACTIVO"
else
    echo "? Nginx: CAÍDO - Reiniciando..."
    sudo systemctl restart nginx
fi

# PostgreSQL
if systemctl is-active --quiet postgresql; then
    echo "? PostgreSQL: ACTIVO"
else
    echo "? PostgreSQL: CAÍDO - Reiniciando..."
    sudo systemctl restart postgresql
fi

# API Health
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5000/api/health)
if [ "$HTTP_CODE" = "200" ]; then
    echo "? API Health: OK"
else
    echo "? API Health: ERROR ($HTTP_CODE)"
fi

# Frontend
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://192.9.135.84)
if [ "$HTTP_CODE" = "200" ]; then
    echo "? Frontend: OK"
else
    echo "? Frontend: ERROR ($HTTP_CODE)"
fi

# Disco
DISK_USE=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$DISK_USE" -gt 90 ]; then
    echo "??  Disco: ${DISK_USE}% (ALERTA)"
else
    echo "? Disco: ${DISK_USE}%"
fi

# Memoria
MEM_USE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
echo "? Memoria: ${MEM_USE}%"

# Último backup
LAST_BACKUP=$(ls -t ~/backups/backup_*.sql.gz 2>/dev/null | head -1)
if [ -n "$LAST_BACKUP" ]; then
    BACKUP_DATE=$(stat -c %y "$LAST_BACKUP" | cut -d. -f1)
    BACKUP_SIZE=$(du -h "$LAST_BACKUP" | cut -f1)
    echo "? Último backup: $BACKUP_DATE ($BACKUP_SIZE)"
else
    echo "??  Sin backups"
fi

echo ""
echo "============================================"
