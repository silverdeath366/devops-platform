#!/bin/bash
# Quick comprehensive test

echo "🧪 Running comprehensive tests..."
echo ""

# Clean start
echo "1. Clean start..."
docker compose -p devops-platform down 2>/dev/null
docker compose -p devops-platform --profile dev up -d --build
echo "Waiting 20 seconds for services..."
sleep 20

echo ""
echo "2. Testing all endpoints..."
bash quick-test.sh

echo ""
echo "3. Testing API functionality..."

echo ""
echo "=== Auth API ==="
echo -n "Register user: "
curl -s -X POST http://localhost:8001/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}' | grep -q "message" && echo "✅" || echo "❌"

echo -n "Login user: "
curl -s -X POST http://localhost:8001/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}' | grep -q "access_token" && echo "✅" || echo "❌"

echo ""
echo "=== User API ==="
echo -n "Create user: "
curl -s -X POST http://localhost:8002/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","username":"johndoe","email":"john@test.com","password":"pass123"}' | grep -q "username" && echo "✅" || echo "❌"

echo -n "List users: "
curl -s http://localhost:8002/users | grep -q "\[" && echo "✅" || echo "❌"

echo ""
echo "=== Task API ==="
echo -n "Create task: "
curl -s -X POST http://localhost:8003/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Task","description":"Testing","user_id":1}' | grep -q "title" && echo "✅" || echo "❌"

echo -n "List tasks: "
curl -s http://localhost:8003/tasks | grep -q "\[" && echo "✅" || echo "❌"

echo ""
echo "=== Notification API ==="
echo -n "Send notification: "
curl -s -X POST http://localhost:8004/notifications/notify \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"message":"Test","notification_type":"email"}' | grep -q "sent" && echo "✅" || echo "❌"

echo ""
echo "4. Testing metrics endpoints..."
for port in 8001 8002 8003 8004; do
    service=$(case $port in 8001) echo "Auth";; 8002) echo "User";; 8003) echo "Task";; 8004) echo "Notification";; esac)
    echo -n "$service metrics: "
    curl -s http://localhost:$port/metrics | grep -q "uptime_seconds" && echo "✅" || echo "❌"
done

echo ""
echo "✅ All tests complete!"
echo ""
echo "Services running. To stop: docker compose -p devops-platform down"

