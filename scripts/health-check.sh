#!/bin/bash
# Health check script for all services

set -e

SERVICES=("auth:8001" "user:8002" "task:8003" "notification:8004")
BASE_URL="${BASE_URL:-http://localhost}"

echo "🏥 Health Check - DevOps Microservices Platform"
echo "================================================"

all_healthy=true

for service_port in "${SERVICES[@]}"; do
    IFS=':' read -r service port <<< "$service_port"
    url="${BASE_URL}:${port}/health"
    
    echo -n "Checking ${service}... "
    
    if response=$(curl -s -f "${url}" 2>/dev/null); then
        status=$(echo "$response" | jq -r '.status' 2>/dev/null || echo "unknown")
        if [ "$status" = "ok" ]; then
            echo "✅ Healthy"
        else
            echo "⚠️  Unhealthy (status: $status)"
            all_healthy=false
        fi
    else
        echo "❌ Unreachable"
        all_healthy=false
    fi
done

echo "================================================"

if $all_healthy; then
    echo "✅ All services are healthy!"
    exit 0
else
    echo "❌ Some services are unhealthy"
    exit 1
fi

