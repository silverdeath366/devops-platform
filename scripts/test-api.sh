#!/bin/bash
# Quick API testing script

set -e

BASE_URL="${BASE_URL:-http://localhost}"
AUTH_PORT="${AUTH_PORT:-8001}"
USER_PORT="${USER_PORT:-8002}"
TASK_PORT="${TASK_PORT:-8003}"
NOTIFICATION_PORT="${NOTIFICATION_PORT:-8004}"

echo "🧪 API Testing - DevOps Microservices Platform"
echo "================================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_endpoint() {
    local name=$1
    local method=$2
    local url=$3
    local data=$4
    
    echo -n "Testing ${name}... "
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "${method}" "${url}")
    else
        response=$(curl -s -w "\n%{http_code}" -X "${method}" -H "Content-Type: application/json" -d "${data}" "${url}")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✅ Success (${http_code})${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed (${http_code})${NC}"
        return 1
    fi
}

echo ""
echo "📍 Testing Auth Service (${BASE_URL}:${AUTH_PORT})"
test_endpoint "Health Check" "GET" "${BASE_URL}:${AUTH_PORT}/health"
test_endpoint "Metrics" "GET" "${BASE_URL}:${AUTH_PORT}/metrics"
test_endpoint "Register User" "POST" "${BASE_URL}:${AUTH_PORT}/auth/register" '{"username":"testuser","password":"testpass123"}'

echo ""
echo "📍 Testing User Service (${BASE_URL}:${USER_PORT})"
test_endpoint "Health Check" "GET" "${BASE_URL}:${USER_PORT}/health"
test_endpoint "List Users" "GET" "${BASE_URL}:${USER_PORT}/users"
test_endpoint "Create User" "POST" "${BASE_URL}:${USER_PORT}/users" '{"name":"John Doe","username":"johndoe","email":"john@example.com","password":"secure123"}'

echo ""
echo "📍 Testing Task Service (${BASE_URL}:${TASK_PORT})"
test_endpoint "Health Check" "GET" "${BASE_URL}:${TASK_PORT}/health"
test_endpoint "List Tasks" "GET" "${BASE_URL}:${TASK_PORT}/tasks"
test_endpoint "Create Task" "POST" "${BASE_URL}:${TASK_PORT}/tasks" '{"title":"Test Task","description":"Testing","user_id":1}'

echo ""
echo "📍 Testing Notification Service (${BASE_URL}:${NOTIFICATION_PORT})"
test_endpoint "Health Check" "GET" "${BASE_URL}:${NOTIFICATION_PORT}/health"
test_endpoint "Send Notification" "POST" "${BASE_URL}:${NOTIFICATION_PORT}/notifications/notify" '{"user_id":1,"message":"Test notification","notification_type":"email"}'

echo ""
echo "================================================"
echo -e "${GREEN}✅ API testing complete!${NC}"

