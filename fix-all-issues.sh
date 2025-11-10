#!/bin/bash
# Fix all known issues

echo "🔧 Fixing all issues..."
echo ""

# Fix 1: Rebuild notification service (likely cache issue)
echo "1. Rebuilding notification service..."
docker compose -p devops-platform stop notification
docker rm -f devops-notification 2>/dev/null || true
docker compose -p devops-platform build --no-cache notification
docker compose -p devops-platform up -d notification
echo "   Waiting 10 seconds..."
sleep 10
echo ""

# Fix 2: Test notification
echo "2. Testing notification service..."
response=$(curl -s -w "%{http_code}" http://localhost:8004/health -o /dev/null 2>&1)
if [ "$response" = "200" ]; then
    echo "   ✅ Notification working!"
else
    echo "   ❌ Still failing. Showing logs:"
    docker logs devops-notification 2>&1 | tail -n 20
fi
echo ""

# Fix 3: Check all containers
echo "3. Checking all containers:"
docker compose -p devops-platform ps
echo ""

# Fix 4: Restart all services to ensure clean state
echo "4. Restarting all services for clean state..."
docker compose -p devops-platform restart
echo "   Waiting 15 seconds..."
sleep 15
echo ""

# Fix 5: Test all endpoints
echo "5. Testing all endpoints:"
for port in 8001 8002 8003 8004; do
    service=$(case $port in 8001) echo "Auth";; 8002) echo "User";; 8003) echo "Task";; 8004) echo "Notification";; esac)
    response=$(curl -s -w "%{http_code}" http://localhost:$port/health -o /dev/null 2>&1)
    echo "   $service: HTTP $response"
done
echo ""

echo "✅ Fix attempt complete!"
echo ""
echo "Run this to retest:"
echo "  bash test-all-features.sh"

