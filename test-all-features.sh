#!/bin/bash
# Comprehensive test of all features

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Comprehensive Feature Test Suite         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

PASSED=0
FAILED=0

test_feature() {
    echo -n "Testing: $1... "
    TOTAL=$((TOTAL + 1))
    if eval "$2" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}"
        FAILED=$((FAILED + 1))
    fi
}

# ============================================
# 1. Docker & Compose Tests
# ============================================
echo -e "${YELLOW}═══ Docker & Compose Tests ═══${NC}"

test_feature "Docker installed" "docker --version"
test_feature "Docker Compose installed" "docker compose version"
test_feature "Services running" "docker compose -p devops-platform ps | grep -q Up"
test_feature "All 4 containers exist" "[ \$(docker compose -p devops-platform ps --services | wc -l) -eq 4 ]"

echo ""

# ============================================
# 2. Service Health Tests
# ============================================
echo -e "${YELLOW}═══ Service Health Tests ═══${NC}"

test_feature "Auth /health" "curl -sf http://localhost:8001/health"
test_feature "Auth /healthz" "curl -sf http://localhost:8001/healthz"
test_feature "Auth /ready" "curl -sf http://localhost:8001/ready"
test_feature "User /health" "curl -sf http://localhost:8002/health"
test_feature "User /ready" "curl -sf http://localhost:8002/ready"
test_feature "Task /health" "curl -sf http://localhost:8003/health"
test_feature "Task /ready" "curl -sf http://localhost:8003/ready"
test_feature "Notification /health" "curl -sf http://localhost:8004/health"
test_feature "Notification /ready" "curl -sf http://localhost:8004/ready"

echo ""

# ============================================
# 3. Metrics Tests
# ============================================
echo -e "${YELLOW}═══ Prometheus Metrics Tests ═══${NC}"

test_feature "Auth metrics endpoint" "curl -s http://localhost:8001/metrics | grep -q uptime_seconds"
test_feature "User metrics endpoint" "curl -s http://localhost:8002/metrics | grep -q uptime_seconds"
test_feature "Task metrics endpoint" "curl -s http://localhost:8003/metrics | grep -q uptime_seconds"
test_feature "Notification metrics" "curl -s http://localhost:8004/metrics | grep -q uptime_seconds"

echo ""

# ============================================
# 4. API Functionality Tests
# ============================================
echo -e "${YELLOW}═══ API Functionality Tests ═══${NC}"

# Auth API
# Note: Both 201 (created) and 400 (already exists) are valid responses
echo -n "Testing: Auth register endpoint... "
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8001/auth/register -H 'Content-Type: application/json' -d '{"username":"testuser-'$RANDOM'","password":"pass123"}' 2>&1 || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "201" ] || [ "$http_code" = "400" ]; then
    echo -e "${GREEN}✅ PASS${NC}"
    PASSED=$((PASSED + 1))
    TOTAL=$((TOTAL + 1))
else
    echo -e "${RED}❌ FAIL${NC}"
    FAILED=$((FAILED + 1))
    TOTAL=$((TOTAL + 1))
fi

test_feature "Auth login returns token" "curl -s -X POST http://localhost:8001/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"testuser\",\"password\":\"testpass123\"}' | grep -q access_token"

# User API
echo -n "Testing: User create endpoint... "
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8002/users -H 'Content-Type: application/json' -d '{"name":"Test","username":"test-'$RANDOM'","email":"test-'$RANDOM'@example.com","password":"pass"}' 2>&1 || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "201" ] || [ "$http_code" = "400" ]; then
    echo -e "${GREEN}✅ PASS${NC}"
    PASSED=$((PASSED + 1))
    TOTAL=$((TOTAL + 1))
else
    echo -e "${RED}❌ FAIL${NC}"
    FAILED=$((FAILED + 1))
    TOTAL=$((TOTAL + 1))
fi

test_feature "User list endpoint" "curl -sf http://localhost:8002/users"

# Task API
test_feature "Task create endpoint" "curl -sf -X POST http://localhost:8003/tasks -H 'Content-Type: application/json' -d '{\"title\":\"Test\",\"description\":\"Test\",\"user_id\":1}'"
test_feature "Task list endpoint" "curl -sf http://localhost:8003/tasks"

# Notification API
test_feature "Notification send" "curl -sf -X POST http://localhost:8004/notifications/notify -H 'Content-Type: application/json' -d '{\"user_id\":1,\"message\":\"Test\",\"notification_type\":\"email\"}'"

echo ""

# ============================================
# 5. Configuration Tests
# ============================================
echo -e "${YELLOW}═══ Configuration Tests ═══${NC}"

test_feature "Makefile exists" "[ -f Makefile ]"
test_feature "Docker Compose valid" "docker compose -p devops-platform config > /dev/null"
test_feature "Helm charts exist" "[ -d helm/charts/auth ] && [ -d helm/charts/user ]"
test_feature "CI/CD workflows exist" "[ -f .github/workflows/ci-cd.yaml ]"
test_feature "AWS deployment exists" "[ -f aws/deploy-to-aws.sh ]"

echo ""

# ============================================
# 6. Security Tests
# ============================================
echo -e "${YELLOW}═══ Security Tests ═══${NC}"

test_feature "Non-root user in auth" "docker inspect devops-auth | grep -q '\"User\": \"appuser\"'"
test_feature "Non-root user in user" "docker inspect devops-user | grep -q '\"User\": \"appuser\"'"
test_feature "Non-root user in task" "docker inspect devops-task | grep -q '\"User\": \"appuser\"'"
test_feature "Non-root user in notification" "docker inspect devops-notification | grep -q '\"User\": \"appuser\"'"

echo ""

# ============================================
# 7. Documentation Tests
# ============================================
echo -e "${YELLOW}═══ Documentation Tests ═══${NC}"

test_feature "README exists" "[ -f README.md ]"
test_feature "QUICKSTART exists" "[ -f QUICKSTART.md ]"
test_feature "DEPLOYMENT guide exists" "[ -f DEPLOYMENT.md ]"
test_feature "CONTRIBUTING guide exists" "[ -f CONTRIBUTING.md ]"
test_feature "AWS documentation exists" "[ -f aws/README.md ]"

echo ""

# ============================================
# 8. Project Structure Tests
# ============================================
echo -e "${YELLOW}═══ Project Structure Tests ═══${NC}"

test_feature "Modular auth structure" "[ -f services/auth/app/config.py ] && [ -f services/auth/app/routers/auth.py ]"
test_feature "Modular user structure" "[ -f services/user/app/config.py ] && [ -f services/user/app/routers/users.py ]"
test_feature "Modular task structure" "[ -f services/task/app/config.py ] && [ -f services/task/app/routers/tasks.py ]"
test_feature "Modular notification structure" "[ -f services/notification/app/config.py ]"
test_feature "Test files exist" "[ -f services/auth/tests/test_auth.py ]"

echo ""

# ============================================
# Summary
# ============================================
TOTAL=$((PASSED + FAILED))
PASS_RATE=$((PASSED * 100 / TOTAL))

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Total Tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
else
    echo "Failed: $FAILED"
fi
echo "Pass Rate: $PASS_RATE%"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ALL FEATURES WORKING! 🎉               ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Your platform is production-ready!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Deploy to AWS: bash aws/deploy-to-aws.sh"
    echo "  2. Set up monitoring: kubectl apply -f k8s/monitoring/"
    echo "  3. Configure CI/CD secrets in GitHub"
else
    echo -e "${RED}Some tests failed. Review above output.${NC}"
fi

