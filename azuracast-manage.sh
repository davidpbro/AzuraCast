#!/bin/bash

# Directory paths
BACKUP_DIR="$HOME/Documents/azuracast-backup"
SSL_DIR="$HOME/Documents/AzuraCast-fresh/ssl"

# Function to show usage
show_usage() {
    echo "AzuraCast Management Script"
    echo "Usage: ./azuracast-manage.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start         - Start AzuraCast containers"
    echo "  stop          - Stop AzuraCast containers"
    echo "  restart       - Restart AzuraCast containers"
    echo "  backup        - Create a backup"
    echo "  restore       - Restore from a backup"
    echo "  list-backups  - List available backups"
    echo "  status        - Show container status"
    echo "  ssl-install   - Install SSL certificates (kpurr.pem and kpurr_key)"
    echo "  ssl-status    - Check SSL certificate status"
    echo ""
    echo "Backup directory: $BACKUP_DIR"
    echo "SSL directory: $SSL_DIR"
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
    # Create backup name with timestamp
    BACKUP_NAME="azuracast_backup_$(date +%Y%m%d_%H%M%S).zip"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    
    # Create backup in container
    docker exec azuracast php /var/azuracast/www/backend/bin/console azuracast:backup "/var/azuracast/backups/$BACKUP_NAME"
    
    # Copy backup from container to Documents
    docker cp "azuracast:/var/azuracast/backups/$BACKUP_NAME" "$BACKUP_PATH"
    
    # Remove backup from container to save space
    docker exec azuracast rm "/var/azuracast/backups/$BACKUP_NAME"
    
    echo "Backup completed: $BACKUP_PATH"
    echo "Backups available in: $BACKUP_DIR"
}

# Function to list available backups
list_backups() {
    echo "Available backups in $BACKUP_DIR:"
    ls -l "$BACKUP_DIR"
}

# Function to restore from backup
restore_azuracast() {
    if [ -z "$1" ]; then
        echo "Error: Please provide the backup file name"
        echo "Available backups:"
        list_backups
        echo "Usage: ./azuracast-manage.sh restore [backup_file_name]"
        exit 1
    fi
    
    # If full path is provided, use it directly, otherwise prepend BACKUP_DIR
    if [[ "$1" == /* ]]; then
        BACKUP_PATH="$1"
    else
        BACKUP_PATH="$BACKUP_DIR/$1"
    fi
    
    if [ ! -f "$BACKUP_PATH" ]; then
        echo "Error: Backup file not found: $BACKUP_PATH"
        echo "Available backups:"
        list_backups
        exit 1
    fi
    
    echo "Stopping AzuraCast..."
    docker compose down
    
    echo "Copying backup file to container..."
    docker cp "$BACKUP_PATH" "azuracast:/var/azuracast/backups/$1"
    
    echo "Restoring from backup: $1"
    docker exec azuracast php /var/azuracast/www/backend/bin/console azuracast:restore "/var/azuracast/backups/$1"
    
    echo "Cleaning up..."
    docker exec azuracast rm "/var/azuracast/backups/$1"
    
    echo "Starting AzuraCast..."
    docker compose up -d
    echo "Restore completed!"
}

# Function to show status
show_status() {
    echo "AzuraCast Container Status:"
    docker compose ps
}

# Function to install SSL certificates
install_ssl() {
    echo "Installing SSL certificates..."
    
    # Check if certificates exist
    if [ ! -f "$SSL_DIR/kpurr.pem" ] || [ ! -f "$SSL_DIR/kpurr_key" ]; then
        echo "Error: SSL certificates not found in $SSL_DIR"
        echo "Please place kpurr.pem and kpurr_key in the SSL directory"
        exit 1
    fi
    
    # Copy certificates to the container
    echo "Copying SSL certificates to container..."
    docker cp "$SSL_DIR/kpurr.pem" azuracast:/var/azuracast/ssl/kpurr.pem
    docker cp "$SSL_DIR/kpurr_key" azuracast:/var/azuracast/ssl/kpurr_key
    
    # Set proper permissions
    docker exec azuracast chmod 644 /var/azuracast/ssl/kpurr.pem
    docker exec azuracast chmod 600 /var/azuracast/ssl/kpurr_key
    
    echo "SSL certificates installed successfully!"
    echo "Please restart AzuraCast to apply changes"
}

# Function to check SSL status
check_ssl() {
    echo "Checking SSL certificate status..."
    
    # Check local SSL files
    echo "Local SSL files in $SSL_DIR:"
    ls -l "$SSL_DIR"
    
    echo -e "\nSSL files in container:"
    docker exec azuracast ls -l /var/azuracast/ssl/
}

# Create required directories if they don't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$SSL_DIR"

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
    list-backups)
        list_backups
        ;;
    status)
        show_status
        ;;
    ssl-install)
        install_ssl
        ;;
    ssl-status)
        check_ssl
        ;;
    *)
        show_usage
        ;;
esac
