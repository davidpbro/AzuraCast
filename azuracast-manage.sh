#!/bin/bash

# Backup directory in Documents
BACKUP_DIR="$HOME/Documents/azuracast-backup"

# Function to show usage
show_usage() {
    echo "AzuraCast Management Script"
    echo "Usage: ./azuracast-manage.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start    - Start AzuraCast containers"
    echo "  stop     - Stop AzuraCast containers"
    echo "  restart  - Restart AzuraCast containers"
    echo "  backup   - Create a backup"
    echo "  restore  - Restore from a backup"
    echo "  list-backups - List available backups"
    echo "  status   - Show container status"
    echo ""
    echo "Backup directory: $BACKUP_DIR"
}

# Function to start containers
start_azuracast() {
    echo "Starting AzuraCast..."
    docker compose up -d
    echo "AzuraCast has been started!"
}

# Function to stop containers
stop_azuracast() {
    echo "Stopping AzuraCast..."
    docker compose down
    echo "AzuraCast has been stopped!"
}

# Function to restart containers
restart_azuracast() {
    echo "Restarting AzuraCast..."
    docker compose down
    docker compose up -d
    echo "AzuraCast has been restarted!"
}

# Function to create backup
backup_azuracast() {
    echo "Creating AzuraCast backup..."
    BACKUP_NAME="azuracast_backup_$(date +%Y%m%d_%H%M%S).zip"
    docker exec azuracast php /var/azuracast/www/backend/bin/console azuracast:backup "/var/azuracast/backups/$BACKUP_NAME"
    echo "Backup completed: $BACKUP_NAME"
}

# Function to restore from backup
restore_azuracast() {
    if [ -z "$1" ]; then
        echo "Error: Please provide the backup file path"
        echo "Usage: ./azuracast-manage.sh restore [backup_file]"
        exit 1
    fi
    
    echo "Stopping AzuraCast..."
    docker compose down
    
    echo "Restoring from backup: $1"
    docker exec azuracast php /var/azuracast/www/backend/bin/console azuracast:restore "$1"
    
    echo "Starting AzuraCast..."
    docker compose up -d
    echo "Restore completed!"
}

# Function to show status
show_status() {
    echo "AzuraCast Container Status:"
    docker compose ps
}

# Main script logic
case "$1" in
    start)
        start_azuracast
        ;;
    stop)
        stop_azuracast
        ;;
    restart)
        restart_azuracast
        ;;
    backup)
        backup_azuracast
        ;;
    restore)
        restore_azuracast "$2"
        ;;
    status)
        show_status
        ;;
    *)
        show_usage
        ;;
esac
