#!/bin/bash
# Backup automático de PostgreSQL
BACKUP_DIR="/home/opc/backups"
DB_NAME="centro_diagnostico"
DB_USER="centro_user"
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7

mkdir -p $BACKUP_DIR

# Extraer password
DB_PASS=$(grep DATABASE_URL /home/opc/centro-diagnostico/backend/.env | sed 's/.*centro_user:\([^@]*\)@.*/\1/')

# Crear backup
PGPASSWORD="$DB_PASS" pg_dump -U $DB_USER -h localhost $DB_NAME | gzip > "$BACKUP_DIR/backup_${DATE}.sql.gz"

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$BACKUP_DIR/backup_${DATE}.sql.gz" | cut -f1)
    echo "[$(date)] Backup OK: backup_${DATE}.sql.gz ($SIZE)"
    
    # Eliminar backups viejos
    find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +$KEEP_DAYS -delete
else
    echo "[$(date)] ERROR en backup"
fi
