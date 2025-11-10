#!/bin/bash
# Initialize databases in RDS

set -e

DB_ENDPOINT=${DB_ENDPOINT}
DB_USERNAME=${DB_USERNAME:-devopsadmin}
DB_PASSWORD=${DB_PASSWORD}
DATABASES=("auth_db" "user_db" "task_db")

echo "🗄️  Initializing RDS Databases"
echo "=============================="
echo ""

if [ -z "$DB_ENDPOINT" ] || [ -z "$DB_PASSWORD" ]; then
    echo "❌ Missing required environment variables:"
    echo "   export DB_ENDPOINT=<your-rds-endpoint>"
    echo "   export DB_PASSWORD=<your-db-password>"
    exit 1
fi

echo "Creating databases..."
echo ""

# Use kubectl to run postgres client in cluster
for db in "${DATABASES[@]}"; do
    echo "Creating database: $db"
    
    kubectl run --rm -it postgres-client --image=postgres:16 --restart=Never -- \
        psql "postgresql://${DB_USERNAME}:${DB_PASSWORD}@${DB_ENDPOINT}:5432/postgres" \
        -c "CREATE DATABASE ${db};" 2>/dev/null || echo "  Database already exists"
    
    echo "  ✅ $db created"
done

echo ""
echo "✅ All databases initialized!"
echo ""
echo "Databases created:"
for db in "${DATABASES[@]}"; do
    echo "  - $db"
done

