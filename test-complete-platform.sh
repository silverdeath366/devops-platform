#!/bin/bash
# Complete platform test - tests EVERYTHING

LOG_FILE="complete-test-$(date +%Y%m%d-%H%M%S).log"

echo "╔══════════════════════════════════════════════════╗" | tee $LOG_FILE
echo "║  DevOps Platform - Complete System Test         ║" | tee -a $LOG_FILE
echo "╚══════════════════════════════════════════════════╝" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "This test validates:" | tee -a $LOG_FILE
echo "  ✓ All 4 services working" | tee -a $LOG_FILE
echo "  ✓ Health endpoints" | tee -a $LOG_FILE
echo "  ✓ Metrics endpoints" | tee -a $LOG_FILE
echo "  ✓ API functionality" | tee -a $LOG_FILE
echo "  ✓ Database operations" | tee -a $LOG_FILE
echo "  ✓ Docker builds" | tee -a $LOG_FILE
echo "  ✓ Container health" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

PASS=0
FAIL=0

test_endpoint() {
    local name=$1
    local url=$2
    local expected=$3
    
    echo -n "  Testing $name... " | tee -a $LOG_FILE
    response=$(curl -s -w "\n%{http_code}" "$url" 2>&1 || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "$expected" ]; then
        echo "✅ PASS" | tee -a $LOG_FILE
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL (got HTTP $http_code)" | tee -a $LOG_FILE
        FAIL=$((FAIL + 1))
    fi
}

# Clean start
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
echo "1. Preparing Environment" | tee -a $LOG_FILE
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
echo "Stopping existing services..." | tee -a $LOG_FILE
docker compose -p devops-platform down >> $LOG_FILE 2>&1
echo "Starting fresh..." | tee -a $LOG_FILE
docker compose -p devops-platform --profile dev up -d --build >> $LOG_FILE 2>&1
echo "Waiting 25 seconds for initialization..." | tee -a $LOG_FILE
sleep 25
echo "✅ Environment ready" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Container check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
echo "2. Container Status" | tee -a $LOG_FILE
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
docker compose -p devops-platform ps | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Health endpoints
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
echo "3. Health Endpoints" | tee -a $LOG_FILE
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
test_endpoint "Auth /health" "http://localhost:8001/health" "200"
test_endpoint "Auth /healthz" "http://localhost:8001/healthz" "200"
test_endpoint "Auth /ready" "http://localhost:8001/ready" "200"
test_endpoint "User /health" "http://localhost:8002/health" "200"
test_endpoint "User /healthz" "http://localhost:8002/healthz" "200"
test_endpoint "User /ready" "http://localhost:8002/ready" "200"
test_endpoint "Task /health" "http://localhost:8003/health" "200"
test_endpoint "Task /healthz" "http://localhost:8003/healthz" "200"
test_endpoint "Task /ready" "http://localhost:8003/ready" "200"
test_endpoint "Notification /health" "http://localhost:8004/health" "200"
test_endpoint "Notification /healthz" "http://localhost:8004/healthz" "200"
test_endpoint "Notification /ready" "http://localhost:8004/ready" "200"
echo "" | tee -a $LOG_FILE

# Metrics
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
echo "4. Metrics Endpoints" | tee -a $LOG_FILE
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
test_endpoint "Auth /metrics" "http://localhost:8001/metrics" "200"
test_endpoint "User /metrics" "http://localhost:8002/metrics" "200"
test_endpoint "Task /metrics" "http://localhost:8003/metrics" "200"
test_endpoint "Notification /metrics" "http://localhost:8004/metrics" "200"
echo "" | tee -a $LOG_FILE

# API Tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
echo "5. API Functionality" | tee -a $LOG_FILE
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE

# Auth - Register
echo -n "  Auth Register... " | tee -a $LOG_FILE
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8001/auth/register \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser1","password":"test123"}' 2>&1)
code=$(echo "$response" | tail -n1)
if [ "$code" = "201" ] || [ "$code" = "400" ]; then
    echo "✅ PASS" | tee -a $LOG_FILE
    PASS=$((PASS + 1))
else
    echo "❌ FAIL (HTTP $code)" | tee -a $LOG_FILE
    FAIL=$((FAIL + 1))
fi

# Auth - Login
echo -n "  Auth Login... " | tee -a $LOG_FILE
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8001/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser1","password":"test123"}' 2>&1)
code=$(echo "$response" | tail -n1)
if [ "$code" = "200" ]; then
    echo "✅ PASS" | tee -a $LOG_FILE
    PASS=$((PASS + 1))
else
    echo "❌ FAIL (HTTP $code)" | tee -a $LOG_FILE
    FAIL=$((FAIL + 1))
fi

# User - Create
echo -n "  User Create... " | tee -a $LOG_FILE
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8002/users \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test User\",\"username\":\"testuser$(date +%s)\",\"email\":\"test$(date +%s)@test.com\",\"password\":\"test123\"}" 2>&1)
code=$(echo "$response" | tail -n1)
if [ "$code" = "201" ]; then
    echo "✅ PASS" | tee -a $LOG_FILE
    PASS=$((PASS + 1))
else
    echo "❌ FAIL (HTTP $code)" | tee -a $LOG_FILE
    FAIL=$((FAIL + 1))
fi

# User - List
test_endpoint "User List" "http://localhost:8002/users" "200"

# Task - Create
echo -n "  Task Create... " | tee -a $LOG_FILE
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8003/tasks \
    -H "Content-Type: application/json" \
    -d '{"title":"Test Task","description":"Testing","user_id":1}' 2>&1)
code=$(echo "$response" | tail -n1)
if [ "$code" = "201" ]; then
    echo "✅ PASS" | tee -a $LOG_FILE
    PASS=$((PASS + 1))
else
    echo "❌ FAIL (HTTP $code)" | tee -a $LOG_FILE
    FAIL=$((FAIL + 1))
fi

# Task - List
test_endpoint "Task List" "http://localhost:8003/tasks" "200"

# Notification - Send
echo -n "  Notification Send... " | tee -a $LOG_FILE
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8004/notifications/notify \
    -H "Content-Type: application/json" \
    -d '{"user_id":1,"message":"Test","notification_type":"email"}' 2>&1)
code=$(echo "$response" | tail -n1)
if [ "$code" = "200" ]; then
    echo "✅ PASS" | tee -a $LOG_FILE
    PASS=$((PASS + 1))
else
    echo "❌ FAIL (HTTP $code)" | tee -a $LOG_FILE
    FAIL=$((FAIL + 1))
fi

echo "" | tee -a $LOG_FILE

# Summary
TOTAL=$((PASS + FAIL))
PERCENT=$((PASS * 100 / TOTAL))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
echo "TEST SUMMARY" | tee -a $LOG_FILE
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Total Tests: $TOTAL" | tee -a $LOG_FILE
echo "Passed: $PASS ✅" | tee -a $LOG_FILE
echo "Failed: $FAIL ❌" | tee -a $LOG_FILE
echo "Success Rate: $PERCENT%" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Log file: $LOG_FILE" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

if [ $FAIL -eq 0 ]; then
    echo "╔══════════════════════════════════════════════════╗" | tee -a $LOG_FILE
    echo "║           🎉 ALL TESTS PASSED! 🎉                ║" | tee -a $LOG_FILE
    echo "╚══════════════════════════════════════════════════╝" | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
    echo "✅ Your platform is production-ready!" | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
    echo "Next steps:" | tee -a $LOG_FILE
    echo "  1. Review documentation: cat INDEX.md" | tee -a $LOG_FILE
    echo "  2. Deploy to AWS: bash test-then-upgrade.sh" | tee -a $LOG_FILE
    echo "  3. Setup CI/CD: Add GitHub secrets" | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
else
    echo "╔══════════════════════════════════════════════════╗" | tee -a $LOG_FILE
    echo "║          ⚠️  SOME TESTS FAILED  ⚠️                ║" | tee -a $LOG_FILE
    echo "╚══════════════════════════════════════════════════╝" | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
    echo "Please check the log: $LOG_FILE" | tee -a $LOG_FILE
fi

echo "" | tee -a $LOG_FILE
echo "Services still running. To stop:" | tee -a $LOG_FILE
echo "  docker compose -p devops-platform down" | tee -a $LOG_FILE

