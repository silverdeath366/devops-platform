#!/bin/bash
# Quick manual test - verifies services start and respond

echo "🧪 Quick Manual Test"
echo "===================="
echo ""

# Stop any existing
echo "1. Stopping existing services..."
docker compose -p devops-platform down 2>&1 | grep -v "Warning: No resource found" || true
echo ""

# Start services
echo "2. Starting services..."
if docker compose -p devops-platform --profile dev up -d; then
    echo "✅ Services started"
else
    echo "❌ Failed to start"
    exit 1
fi
echo ""

# Wait
echo "3. Waiting 15 seconds for services to initialize..."
sleep 15
echo ""

# Check status
echo "4. Checking container status..."
docker compose -p devops-platform ps
echo ""

# Test endpoints
echo "5. Testing health endpoints..."
echo ""

for port in 8001 8002 8003 8004; do
    service=$(case $port in
        8001) echo "Auth";;
        8002) echo "User";;
        8003) echo "Task";;
        8004) echo "Notification";;
    esac)
    
    echo -n "  $service (port $port): "
    response=$(curl -s -w "%{http_code}" http://localhost:$port/health -o /dev/null 2>&1)
    
    if [ "$response" = "200" ]; then
        echo "✅ PASS (HTTP $response)"
    else
        echo "❌ FAIL (HTTP $response)"
    fi
done
echo ""

# Show logs snippet
echo "6. Recent logs (last 5 lines per service):"
echo ""
for service in auth user task notification; do
    echo "=== $service ==="
    docker logs devops-$service 2>&1 | tail -n 5 || echo "No logs"
    echo ""
done

echo "===================="
echo "✅ Quick test complete!"
echo ""
echo "Services are still running."
echo "To view logs: docker compose -p devops-platform logs -f"
echo "To stop: docker compose -p devops-platform down"

