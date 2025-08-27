#!/bin/bash

# AzuraCast Ports Configuration Script
# This script allows you to change the ports used by AzuraCast

echo "🔧 AzuraCast Ports Configuration"
echo "================================"
echo ""
echo "Choose port configuration:"
echo "1) Standard ports (80, 443) - Requires admin/sudo for ports under 1024"
echo "2) Alternative ports (8080, 8443) - No special permissions needed"
echo "3) Custom ports (manual configuration)"
echo ""
echo -n "Select option [1-3]: "
read CHOICE

case $CHOICE in
    1)
        echo ""
        echo "Setting standard ports (80, 443)..."
        # Update docker-compose.dev.yml directly for standard ports
        sed -i '' 's/"0.0.0.0:[0-9]*:80"/"0.0.0.0:80:80"/g' docker-compose.dev.yml
        sed -i '' 's/"0.0.0.0:[0-9]*:443"/"0.0.0.0:443:443"/g' docker-compose.dev.yml
        echo "✅ Configured for standard ports (80, 443)"
        ;;
    2)
        echo ""
        echo "Setting alternative ports (8080, 8443)..."
        # Update docker-compose.dev.yml directly for alternative ports
        sed -i '' 's/"0.0.0.0:[0-9]*:80"/"0.0.0.0:8080:80"/g' docker-compose.dev.yml
        sed -i '' 's/"0.0.0.0:[0-9]*:443"/"0.0.0.0:8443:443"/g' docker-compose.dev.yml
        echo "✅ Configured for alternative ports (8080, 8443)"
        ;;
    3)
        echo ""
        echo "Custom port configuration..."
        ./docker.sh change-ports
        exit 0
        ;;
    *)
        echo "Invalid choice. Using custom configuration..."
        ./docker.sh change-ports
        exit 0
        ;;
esac

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Restart containers with new port configuration
echo ""
echo "🔄 Restarting AzuraCast with new port configuration..."
docker-compose -f docker-compose.dev.yml down --timeout 60
docker-compose -f docker-compose.dev.yml up -d

echo ""
echo "🎉 Port configuration complete!"
echo ""
echo "🌐 AzuraCast should now be accessible on your new ports."
echo "Check the output above for the specific URLs."
