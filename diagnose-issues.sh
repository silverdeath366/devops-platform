#!/bin/bash
# Diagnose test failures

echo "🔍 Diagnosing Test Failures"
echo "=========================="
echo ""

echo "1. Container Status:"
docker ps -a
echo ""

echo "2. Docker Compose Status:"
docker compose -p devops-platform ps
echo ""

echo "3. Notification Service Logs:"
docker logs devops-notification 2>&1 | tail -n 50
echo ""

echo "4. Testing Notification Endpoint:"
curl -v http://localhost:8004/health 2>&1
echo ""

echo "5. User Service Logs (for user create failure):"
docker logs devops-user 2>&1 | tail -n 30
echo ""

echo "6. Testing User Create:"
curl -v -X POST http://localhost:8002/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","username":"diagtest","email":"diag@test.com","password":"test123"}' 2>&1
echo ""

echo "7. Checking which containers have non-root user:"
for service in auth user task notification; do
    echo -n "$service: "
    docker inspect devops-$service 2>/dev/null | grep -A 2 '"User"' | grep '"User"' || echo "Not found"
done
echo ""

echo "8. Network connectivity:"
docker network inspect devops-network 2>&1 | head -n 30
echo ""

echo "Done! Send this output."

