#!/bin/bash
# ============================================
# Comprehensive Test Script - Non-Stopping Version
# Runs ALL tests even if some fail
# ============================================

# DO NOT exit on errors - we want to test everything
# set -e  # REMOVED - we want to continue on errors

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Log file
LOG_FILE="test-results-$(date +%Y%m%d-%H%M%S).log"

# Error collection
declare -a ERRORS

# Functions
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

test_start() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "  Testing $1... " | tee -a "$LOG_FILE"
}

test_pass() {
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log "${GREEN}✅ PASS${NC}"
}

test_fail() {
    FAILED_TESTS=$((FAILED_TESTS + 1))
    log "${RED}❌ FAIL${NC}"
    if [ -n "$1" ]; then
        log "    Error: $1"
        ERRORS+=("$TOTAL_TESTS: $1")
    fi
}

test_warn() {
    log "${YELLOW}⚠️  WARN${NC}"
    if [ -n "$1" ]; then
        log "    Warning: $1"
    fi
}

section() {
    log "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BLUE}$1${NC}"
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Start
log "${GREEN}╔════════════════════════════════════════════╗${NC}"
log "${GREEN}║   DevOps Platform - Comprehensive Test    ║${NC}"
log "${GREEN}║         (Non-Stopping Version)             ║${NC}"
log "${GREEN}╚════════════════════════════════════════════╝${NC}"
log ""
log "Started: $(date)"
log "Log file: $LOG_FILE"
log ""

# ============================================
# 1. Prerequisites Check
# ============================================
section "1. Checking Prerequisites"

# Check Docker
test_start "Docker installation"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>&1 || echo "unknown")
    test_pass
    log "    Version: $DOCKER_VERSION"
else
    test_fail "Docker not found"
fi

# Check Docker Compose
test_start "Docker Compose installation"
if docker compose version &> /dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version 2>&1 || echo "unknown")
    test_pass
    log "    Version: $COMPOSE_VERSION"
else
    test_fail "Docker Compose not found"
fi

# Check Python
test_start "Python installation"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 || echo "unknown")
    test_pass
    log "    Version: $PYTHON_VERSION"
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version 2>&1 || echo "unknown")
    test_pass
    log "    Version: $PYTHON_VERSION"
else
    test_fail "Python not found"
fi

# Check curl
test_start "curl installation"
if command -v curl &> /dev/null; then
    test_pass
else
    test_warn "curl not found - will skip API tests"
fi

# ============================================
# 2. Project Structure Check
# ============================================
section "2. Checking Project Structure"

REQUIRED_DIRS=(
    "services/auth/app"
    "services/user/app"
    "services/task/app"
    "services/notification/app"
    "services/auth/tests"
    "services/user/tests"
    "services/task/tests"
    "services/notification/tests"
    "helm/charts"
    "scripts"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    test_start "Directory: $dir"
    if [ -d "$dir" ]; then
        test_pass
    else
        test_fail "Directory not found"
    fi
done

REQUIRED_FILES=(
    "docker-compose.yaml"
    "Makefile"
    "README.md"
    "requirements-dev.txt"
    "pyproject.toml"
)

for file in "${REQUIRED_FILES[@]}"; do
    test_start "File: $file"
    if [ -f "$file" ]; then
        test_pass
    else
        test_fail "File not found"
    fi
done

# ============================================
# 3. Service Files Check
# ============================================
section "3. Checking Service Files"

SERVICES=("auth" "user" "task" "notification")

for service in "${SERVICES[@]}"; do
    test_start "Service $service structure"
    missing_files=()
    [ ! -f "services/$service/app/main.py" ] && missing_files+=("main.py")
    [ ! -f "services/$service/app/config.py" ] && missing_files+=("config.py")
    [ ! -f "services/$service/Dockerfile" ] && missing_files+=("Dockerfile")
    [ ! -f "services/$service/requirements.txt" ] && missing_files+=("requirements.txt")
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        test_pass
    else
        test_fail "Missing files: ${missing_files[*]}"
    fi
done

# ============================================
# 4. Docker Build Test
# ============================================
section "4. Testing Docker Builds"

for service in "${SERVICES[@]}"; do
    test_start "Building $service Docker image"
    if docker build -t test-$service:test services/$service >> "$LOG_FILE" 2>&1; then
        test_pass
    else
        test_fail "Build failed - check log for details"
        echo "=== Build error for $service ===" >> "$LOG_FILE"
        docker build -t test-$service:test services/$service >> "$LOG_FILE" 2>&1 || true
    fi
done

# ============================================
# 5. Docker Compose Configuration
# ============================================
section "5. Checking Docker Compose"

test_start "Docker Compose file syntax"
if docker compose -p devops-platform config > /dev/null 2>&1; then
    test_pass
else
    test_fail "Invalid docker-compose.yaml"
    docker compose -p devops-platform config >> "$LOG_FILE" 2>&1 || true
fi

# ============================================
# 6. Stop Existing Services
# ============================================
section "6. Cleaning Up Old Services"

test_start "Stopping existing containers"
docker compose -p devops-platform --profile dev down >> "$LOG_FILE" 2>&1 || true
docker compose -p devops-platform --profile prod down >> "$LOG_FILE" 2>&1 || true
docker compose -p devops-platform down >> "$LOG_FILE" 2>&1 || true
test_pass

test_start "Removing old test containers"
docker rm -f devops-auth devops-user devops-task devops-notification >> "$LOG_FILE" 2>&1 || true
test_pass

# ============================================
# 7. Start Services with Docker Compose
# ============================================
section "7. Starting Services"

test_start "Starting services with Docker Compose"
if docker compose -p devops-platform --profile dev up -d >> "$LOG_FILE" 2>&1; then
    test_pass
else
    test_fail "Failed to start services"
    docker compose -p devops-platform --profile dev ps >> "$LOG_FILE" 2>&1 || true
fi

test_start "Waiting for services (20 seconds)"
sleep 20
test_pass

# ============================================
# 8. Container Status Check
# ============================================
section "8. Checking Container Status"

for service in "${SERVICES[@]}"; do
    test_start "Container devops-$service exists"
    if docker ps -a --format '{{.Names}}' | grep -q "devops-$service"; then
        test_pass
    else
        test_fail "Container not found"
    fi
    
    test_start "Container devops-$service running"
    if docker ps --format '{{.Names}}' | grep -q "devops-$service"; then
        test_pass
    else
        test_fail "Container not running"
        docker ps -a | grep "devops-$service" >> "$LOG_FILE" 2>&1 || true
    fi
done

# ============================================
# 9. Container Logs Check
# ============================================
section "9. Collecting Container Logs"

for service in "${SERVICES[@]}"; do
    test_start "Collecting logs for $service"
    docker logs devops-$service >> "$LOG_FILE" 2>&1 || true
    test_pass
done

# ============================================
# 10. Health Endpoint Tests
# ============================================
section "10. Testing Health Endpoints"

PORTS=("8001" "8002" "8003" "8004")
SERVICE_NAMES=("auth" "user" "task" "notification")

if command -v curl &> /dev/null; then
    for i in "${!PORTS[@]}"; do
        port="${PORTS[$i]}"
        service="${SERVICE_NAMES[$i]}"
        
        # Test /health
        test_start "$service /health (port $port)"
        response=$(curl -s -w "\n%{http_code}" http://localhost:$port/health 2>&1 || echo -e "\n000")
        http_code=$(echo "$response" | tail -n1)
        
        if [ "$http_code" = "200" ]; then
            test_pass
        elif [ "$http_code" = "000" ]; then
            test_fail "Connection refused or service not responding"
        else
            test_fail "HTTP $http_code"
        fi
        echo "Response for $service /health: $http_code" >> "$LOG_FILE"
        echo "$response" >> "$LOG_FILE"
        
        # Test /healthz
        test_start "$service /healthz (port $port)"
        response=$(curl -s -w "\n%{http_code}" http://localhost:$port/healthz 2>&1 || echo -e "\n000")
        http_code=$(echo "$response" | tail -n1)
        
        if [ "$http_code" = "200" ]; then
            test_pass
        else
            test_fail "HTTP $http_code"
        fi
        
        # Test /ready
        test_start "$service /ready (port $port)"
        response=$(curl -s -w "\n%{http_code}" http://localhost:$port/ready 2>&1 || echo -e "\n000")
        http_code=$(echo "$response" | tail -n1)
        
        if [ "$http_code" = "200" ]; then
            test_pass
        else
            test_fail "HTTP $http_code"
        fi
    done
else
    log "${YELLOW}Skipping health endpoint tests - curl not installed${NC}"
fi

# ============================================
# 11. Metrics Endpoint Tests
# ============================================
section "11. Testing Metrics Endpoints"

if command -v curl &> /dev/null; then
    for i in "${!PORTS[@]}"; do
        port="${PORTS[$i]}"
        service="${SERVICE_NAMES[$i]}"
        
        test_start "$service /metrics (port $port)"
        response=$(curl -s http://localhost:$port/metrics 2>&1 || echo "ERROR")
        
        if echo "$response" | grep -q "uptime_seconds"; then
            test_pass
        else
            test_fail "Metrics not found or malformed"
            echo "Metrics response for $service: $response" >> "$LOG_FILE"
        fi
    done
else
    log "${YELLOW}Skipping metrics tests - curl not installed${NC}"
fi

# ============================================
# 12. API Functionality Tests
# ============================================
section "12. Testing API Functionality"

if command -v curl &> /dev/null; then
    # Auth - Register
    test_start "Auth: POST /auth/register"
    response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8001/auth/register \
        -H "Content-Type: application/json" \
        -d '{"username":"testuser","password":"testpass123"}' 2>&1 || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" = "201" ] || [ "$http_code" = "400" ]; then
        test_pass
    else
        test_fail "HTTP $http_code"
    fi
    echo "Auth register response: $response" >> "$LOG_FILE"
    
    # Auth - Login
    test_start "Auth: POST /auth/login"
    response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8001/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"testuser","password":"testpass123"}' 2>&1 || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" = "200" ]; then
        test_pass
    else
        test_fail "HTTP $http_code"
    fi
    
    # User - Create
    test_start "User: POST /users"
    response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8002/users \
        -H "Content-Type: application/json" \
        -d '{"name":"John Doe","username":"johndoe","email":"john@example.com","password":"secure123"}' 2>&1 || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" = "201" ] || [ "$http_code" = "400" ]; then
        test_pass
    else
        test_fail "HTTP $http_code"
    fi
    
    # User - List
    test_start "User: GET /users"
    response=$(curl -s -w "\n%{http_code}" http://localhost:8002/users 2>&1 || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" = "200" ]; then
        test_pass
    else
        test_fail "HTTP $http_code"
    fi
    
    # Task - Create
    test_start "Task: POST /tasks"
    response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8003/tasks \
        -H "Content-Type: application/json" \
        -d '{"title":"Test Task","description":"Testing","user_id":1}' 2>&1 || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" = "201" ]; then
        test_pass
    else
        test_fail "HTTP $http_code"
    fi
    
    # Task - List
    test_start "Task: GET /tasks"
    response=$(curl -s -w "\n%{http_code}" http://localhost:8003/tasks 2>&1 || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" = "200" ]; then
        test_pass
    else
        test_fail "HTTP $http_code"
    fi
    
    # Notification - Send
    test_start "Notification: POST /notifications/notify"
    response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8004/notifications/notify \
        -H "Content-Type: application/json" \
        -d '{"user_id":1,"message":"Test","notification_type":"email"}' 2>&1 || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" = "200" ]; then
        test_pass
    else
        test_fail "HTTP $http_code"
    fi
else
    log "${YELLOW}Skipping API tests - curl not installed${NC}"
fi

# ============================================
# 13. Docker Compose Status
# ============================================
section "13. Final Docker Compose Status"

log "\nDocker Compose Services:"
docker compose -p devops-platform ps 2>&1 | tee -a "$LOG_FILE" || true

log "\nAll Containers:"
docker ps -a | grep "devops" 2>&1 | tee -a "$LOG_FILE" || true

# ============================================
# 14. Collect Full Logs
# ============================================
section "14. Collecting All Container Logs"

for service in "${SERVICES[@]}"; do
    log "\n=== Logs for $service ===" 
    docker logs devops-$service 2>&1 | tail -n 50 | tee -a "$LOG_FILE" || true
done

# ============================================
# Final Results
# ============================================
log ""
log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
log "${GREEN}Test Summary${NC}"
log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
log ""
log "Total Tests:  $TOTAL_TESTS"
log "${GREEN}Passed:       $PASSED_TESTS${NC}"

if [ $FAILED_TESTS -gt 0 ]; then
    log "${RED}Failed:       $FAILED_TESTS${NC}"
else
    log "Failed:       $FAILED_TESTS"
fi

PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
log "Pass Rate:    $PASS_RATE%"
log ""

if [ ${#ERRORS[@]} -gt 0 ]; then
    log "${RED}Failed Tests:${NC}"
    for error in "${ERRORS[@]}"; do
        log "  - $error"
    done
    log ""
fi

log "Completed: $(date)"
log "Log file: $LOG_FILE"
log ""

log "${YELLOW}Services are still running.${NC}"
log "${YELLOW}To stop: docker compose -p devops-platform --profile dev down${NC}"
log ""

if [ $FAILED_TESTS -eq 0 ]; then
    log "${GREEN}╔════════════════════════════════════════════╗${NC}"
    log "${GREEN}║           ALL TESTS PASSED! 🎉             ║${NC}"
    log "${GREEN}╚════════════════════════════════════════════╝${NC}"
else
    log "${RED}╔════════════════════════════════════════════╗${NC}"
    log "${RED}║         SOME TESTS FAILED ❌                ║${NC}"
    log "${RED}╚════════════════════════════════════════════╝${NC}"
    log ""
    log "${YELLOW}Please send the log file: $LOG_FILE${NC}"
fi

log ""
log "To view the log:"
log "  cat $LOG_FILE"
log ""
log "To copy log to clipboard:"
log "  # Linux: cat $LOG_FILE | xclip -selection clipboard"
log "  # Mac:   cat $LOG_FILE | pbcopy"
log "  # Or just: cat $LOG_FILE"
