#!/bin/bash
# Quick test - just the essentials, never stops
# For fast error collection

LOG_FILE="quick-test-$(date +%Y%m%d-%H%M%S).log"

echo "Quick Test - $(date)" | tee $LOG_FILE
echo "================================" | tee -a $LOG_FILE
echo ""

# 1. Prerequisites
echo "1. Prerequisites:" | tee -a $LOG_FILE
docker --version 2>&1 | tee -a $LOG_FILE || echo "ERROR: Docker not found" | tee -a $LOG_FILE
docker compose version 2>&1 | tee -a $LOG_FILE || echo "ERROR: Docker Compose not found" | tee -a $LOG_FILE
python3 --version 2>&1 | tee -a $LOG_FILE || python --version 2>&1 | tee -a $LOG_FILE || echo "ERROR: Python not found" | tee -a $LOG_FILE
echo ""

# 2. Project files
echo "2. Project Files:" | tee -a $LOG_FILE
ls -la services/*/app/main.py 2>&1 | tee -a $LOG_FILE || echo "ERROR: Service files missing" | tee -a $LOG_FILE
ls -la docker-compose.yaml 2>&1 | tee -a $LOG_FILE || echo "ERROR: docker-compose.yaml missing" | tee -a $LOG_FILE
echo ""

# 3. Clean up
echo "3. Cleaning up..." | tee -a $LOG_FILE
docker compose down 2>&1 | tee -a $LOG_FILE || true
echo ""

# 4. Build images
echo "4. Building images..." | tee -a $LOG_FILE
for service in auth user task notification; do
    echo "  Building $service..." | tee -a $LOG_FILE
    docker build -t test-$service:test services/$service 2>&1 | tee -a $LOG_FILE
    echo "  Build exit code for $service: $?" | tee -a $LOG_FILE
done
echo ""

# 5. Start services
echo "5. Starting services..." | tee -a $LOG_FILE
docker compose --profile dev up -d 2>&1 | tee -a $LOG_FILE
echo "Start exit code: $?" | tee -a $LOG_FILE
echo ""

# 6. Wait
echo "6. Waiting 20 seconds..." | tee -a $LOG_FILE
sleep 20
echo ""

# 7. Check containers
echo "7. Container status:" | tee -a $LOG_FILE
docker ps -a 2>&1 | tee -a $LOG_FILE
echo ""

# 8. Test health endpoints
echo "8. Testing endpoints:" | tee -a $LOG_FILE
for port in 8001 8002 8003 8004; do
    echo "  Port $port:" | tee -a $LOG_FILE
    curl -s -w "\nHTTP Code: %{http_code}\n" http://localhost:$port/health 2>&1 | tee -a $LOG_FILE || echo "  ERROR: Failed to connect to port $port" | tee -a $LOG_FILE
    echo ""
done

# 9. Collect logs
echo "9. Container logs:" | tee -a $LOG_FILE
for service in auth user task notification; do
    echo "=== Logs for $service ===" | tee -a $LOG_FILE
    docker logs devops-$service 2>&1 | tail -n 30 | tee -a $LOG_FILE || echo "ERROR: No logs for $service" | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
done

echo ""
echo "================================" | tee -a $LOG_FILE
echo "Test complete - $(date)" | tee -a $LOG_FILE
echo "Log saved to: $LOG_FILE" | tee -a $LOG_FILE
echo ""
echo "To view full log: cat $LOG_FILE"
echo "Services still running. To stop: docker compose down"

