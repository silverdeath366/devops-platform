#!/bin/bash
# Fix the task service

echo "🔧 Fixing task service..."
echo ""

echo "1. Stopping task service..."
docker compose -p devops-platform stop task

echo ""
echo "2. Removing old task container..."
docker rm -f devops-task 2>/dev/null || true

echo ""
echo "3. Rebuilding task service (no cache)..."
docker compose -p devops-platform build --no-cache task

echo ""
echo "4. Starting task service..."
docker compose -p devops-platform up -d task

echo ""
echo "5. Waiting 10 seconds..."
sleep 10

echo ""
echo "6. Testing task service..."
response=$(curl -s -w "%{http_code}" http://localhost:8003/health -o /dev/null)

if [ "$response" = "200" ]; then
    echo "✅ Task service is now working! (HTTP $response)"
else
    echo "❌ Task service still failing (HTTP $response)"
    echo ""
    echo "Showing logs:"
    docker logs devops-task 2>&1 | tail -n 20
fi

echo ""
echo "Done!"

