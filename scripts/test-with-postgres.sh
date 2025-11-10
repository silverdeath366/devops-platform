#!/bin/bash
# Test services with PostgreSQL (production-like environment)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Testing with PostgreSQL (Production Mode)${NC}"
echo ""

# Stop existing services
echo "1. Stopping existing services..."
docker compose -p devops-platform down 2>/dev/null

# Start with PostgreSQL
echo ""
echo "2. Starting services with PostgreSQL..."
docker compose -p devops-platform --profile dev --profile postgres up -d

echo ""
echo "3. Waiting for PostgreSQL to be ready..."
sleep 10

# Check PostgreSQL health
echo ""
echo "4. Checking PostgreSQL..."
docker exec devops-postgres pg_isready -U devops_user || echo "PostgreSQL not ready yet"

echo ""
echo "5. Waiting for services (20 seconds)..."
sleep 20

echo ""
echo "6. Testing health endpoints..."
for port in 8001 8002 8003 8004; do
    service=$(case $port in 8001) echo "Auth";; 8002) echo "User";; 8003) echo "Task";; 8004) echo "Notification";; esac)
    echo -n "  $service: "
    response=$(curl -s -w "%{http_code}" http://localhost:$port/health -o /dev/null 2>&1)
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${YELLOW}❌ FAIL (HTTP $response)${NC}"
    fi
done

echo ""
echo "7. Testing database connectivity..."
echo "Checking if services can write to PostgreSQL..."

# Test auth service database
echo -n "  Auth DB: "
curl -s -X POST http://localhost:8001/auth/register \
    -H "Content-Type: application/json" \
    -d '{"username":"pgtest","password":"testpass"}' | grep -q "message\|already exists" && echo -e "${GREEN}✅${NC}" || echo -e "${YELLOW}❌${NC}"

# Test user service database
echo -n "  User DB: "
curl -s -X POST http://localhost:8002/users \
    -H "Content-Type: application/json" \
    -d '{"name":"PG Test","username":"pguser","email":"pg@test.com","password":"test"}' | grep -q "username\|already exists" && echo -e "${GREEN}✅${NC}" || echo -e "${YELLOW}❌${NC}"

# Test task service database
echo -n "  Task DB: "
curl -s -X POST http://localhost:8003/tasks \
    -H "Content-Type: application/json" \
    -d '{"title":"PG Task","description":"Test","user_id":1}' | grep -q "title" && echo -e "${GREEN}✅${NC}" || echo -e "${YELLOW}❌${NC}"

echo ""
echo -e "${GREEN}✓ PostgreSQL testing complete!${NC}"
echo ""
echo "PostgreSQL container: devops-postgres"
echo "To connect: docker exec -it devops-postgres psql -U devops_user -d auth_db"
echo "To stop: docker compose -p devops-platform down"

