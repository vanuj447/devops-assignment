#!/bin/bash

# MySQL backup script
BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
MYSQL_USER="root"
MYSQL_PASSWORD="mysecurepassword"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Get list of databases
databases=$(mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)")

# Backup each database
for db in $databases; do
    echo "Backing up database: $db"
    mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD --databases $db > "$BACKUP_DIR/${db}_${DATE}.sql"
done

# Compress backupss
cd $BACKUP_DIR
tar -czf "mysql_backup_${DATE}.tar.gz" *.sql
rm *.sql

# Keep only last 7 days of backups
find $BACKUP_DIR -name "mysql_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $(date)"