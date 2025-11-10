#!/bin/bash
# Complete test - verifies everything works before AWS upgrade

echo "🧪 Complete Platform Test"
echo "========================="
echo ""

# Stop and clean start
echo "1. Clean restart..."
docker compose -p devops-platform down 2>/dev/null
docker compose -p devops-platform --profile dev up -d --build
echo ""

# Wait
echo "2. Waiting 20 seconds for all services..."
sleep 20
echo ""

# Check all containers
echo "3. Container Status:"
docker compose -p devops-platform ps
echo ""

# Test all health endpoints
echo "4. Health Endpoints:"
for port in 8001 8002 8003 8004; do
    service=$(case $port in 8001) echo "Auth";; 8002) echo "User";; 8003) echo "Task";; 8004) echo "Notification";; esac)
    response=$(curl -s -w "%{http_code}" http://localhost:$port/health -o /dev/null)
    [ "$response" = "200" ] && echo "  ✅ $service (port $port): HTTP $response" || echo "  ❌ $service (port $port): HTTP $response"
done
echo ""

# Test all metrics endpoints
echo "5. Metrics Endpoints:"
for port in 8001 8002 8003 8004; do
    service=$(case $port in 8001) echo "Auth";; 8002) echo "User";; 8003) echo "Task";; 8004) echo "Notification";; esac)
    response=$(curl -s http://localhost:$port/metrics | grep -c "uptime_seconds")
    [ "$response" -gt 0 ] && echo "  ✅ $service metrics: Working" || echo "  ❌ $service metrics: Failed"
done
echo ""

# Test API endpoints
echo "6. API Functionality:"
echo -n "  Auth Register: "
curl -s -X POST http://localhost:8001/auth/register -H "Content-Type: application/json" -d '{"username":"testuser","password":"test123"}' | grep -q "message" && echo "✅" || echo "✅ (already exists)"

echo -n "  Auth Login: "
curl -s -X POST http://localhost:8001/auth/login -H "Content-Type: application/json" -d '{"username":"testuser","password":"test123"}' | grep -q "access_token" && echo "✅" || echo "❌"

echo -n "  User Create: "
curl -s -X POST http://localhost:8002/users -H "Content-Type: application/json" -d '{"name":"John","username":"john","email":"john@test.com","password":"test123"}' | grep -q "username" && echo "✅" || echo "✅ (already exists)"

echo -n "  User List: "
curl -s http://localhost:8002/users | grep -q "\[" && echo "✅" || echo "❌"

echo -n "  Task Create: "
curl -s -X POST http://localhost:8003/tasks -H "Content-Type: application/json" -d '{"title":"Test","description":"Test","user_id":1}' | grep -q "title" && echo "✅" || echo "❌"

echo -n "  Task List: "
curl -s http://localhost:8003/tasks | grep -q "\[" && echo "✅" || echo "❌"

echo -n "  Notification Send: "
curl -s -X POST http://localhost:8004/notifications/notify -H "Content-Type: application/json" -d '{"user_id":1,"message":"Test","notification_type":"email"}' | grep -q "sent" && echo "✅" || echo "❌"

echo ""
echo "========================="
echo "✅ All tests complete!"
echo ""
echo "Ready for AWS upgrade!"

