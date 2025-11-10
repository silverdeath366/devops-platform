@echo off
REM ============================================
REM Windows Batch Test Script
REM Tests all components of the DevOps Platform
REM ============================================

setlocal enabledelayedexpansion

set TOTAL_TESTS=0
set PASSED_TESTS=0
set FAILED_TESTS=0
set LOG_FILE=test-results-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2%.log

echo ======================================== > %LOG_FILE%
echo DevOps Platform - Comprehensive Test >> %LOG_FILE%
echo ======================================== >> %LOG_FILE%
echo Started: %date% %time% >> %LOG_FILE%
echo. >> %LOG_FILE%

echo.
echo ╔════════════════════════════════════════════╗
echo ║   DevOps Platform - Comprehensive Test    ║
echo ╚════════════════════════════════════════════╝
echo.
echo Log file: %LOG_FILE%
echo.

REM ============================================
REM 1. Prerequisites Check
REM ============================================
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 1. Checking Prerequisites
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

echo   Testing Docker installation...
docker --version >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✅ PASS - Docker found
    docker --version >> %LOG_FILE%
) else (
    echo   ❌ FAIL - Docker not found
)

echo   Testing Docker Compose...
docker compose version >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✅ PASS - Docker Compose found
    docker compose version >> %LOG_FILE%
) else (
    echo   ❌ FAIL - Docker Compose not found
)

echo   Testing Python installation...
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✅ PASS - Python found
    python --version >> %LOG_FILE%
) else (
    echo   ❌ FAIL - Python not found
)

REM ============================================
REM 2. Project Structure Check
REM ============================================
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 2. Checking Project Structure
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

if exist services\auth\app (echo   ✅ PASS - services/auth/app) else (echo   ❌ FAIL - services/auth/app missing)
if exist services\user\app (echo   ✅ PASS - services/user/app) else (echo   ❌ FAIL - services/user/app missing)
if exist services\task\app (echo   ✅ PASS - services/task/app) else (echo   ❌ FAIL - services/task/app missing)
if exist services\notification\app (echo   ✅ PASS - services/notification/app) else (echo   ❌ FAIL - services/notification/app missing)
if exist docker-compose.yaml (echo   ✅ PASS - docker-compose.yaml) else (echo   ❌ FAIL - docker-compose.yaml missing)
if exist Makefile (echo   ✅ PASS - Makefile) else (echo   ❌ FAIL - Makefile missing)

REM ============================================
REM 3. Docker Build Test
REM ============================================
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 3. Testing Docker Builds
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

echo   Building auth Docker image...
docker build -t test-auth:test services/auth >> %LOG_FILE% 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Building user Docker image...
docker build -t test-user:test services/user >> %LOG_FILE% 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Building task Docker image...
docker build -t test-task:test services/task >> %LOG_FILE% 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Building notification Docker image...
docker build -t test-notification:test services/notification >> %LOG_FILE% 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

REM ============================================
REM 4. Start Services
REM ============================================
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 4. Starting Services with Docker Compose
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

echo   Stopping any existing containers...
docker compose --profile dev down >> %LOG_FILE% 2>&1
echo   ✅ Done

echo   Starting services...
docker compose --profile dev up -d >> %LOG_FILE% 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Waiting for services to be ready (15 seconds)...
timeout /t 15 /nobreak >nul
echo   ✅ Done

REM ============================================
REM 5. Container Health Check
REM ============================================
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 5. Checking Container Health
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

docker ps | findstr "devops-auth" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS - auth container running) else (echo   ❌ FAIL - auth container not running)

docker ps | findstr "devops-user" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS - user container running) else (echo   ❌ FAIL - user container not running)

docker ps | findstr "devops-task" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS - task container running) else (echo   ❌ FAIL - task container not running)

docker ps | findstr "devops-notification" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS - notification container running) else (echo   ❌ FAIL - notification container not running)

REM ============================================
REM 6. Health Endpoint Tests
REM ============================================
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 6. Testing Health Endpoints
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

echo   Testing auth /health...
curl -s http://localhost:8001/health >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Testing user /health...
curl -s http://localhost:8002/health >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Testing task /health...
curl -s http://localhost:8003/health >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Testing notification /health...
curl -s http://localhost:8004/health >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

REM ============================================
REM 7. Metrics Endpoint Tests
REM ============================================
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 7. Testing Metrics Endpoints
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

echo   Testing auth /metrics...
curl -s http://localhost:8001/metrics | findstr "uptime_seconds" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Testing user /metrics...
curl -s http://localhost:8002/metrics | findstr "uptime_seconds" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Testing task /metrics...
curl -s http://localhost:8003/metrics | findstr "uptime_seconds" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Testing notification /metrics...
curl -s http://localhost:8004/metrics | findstr "uptime_seconds" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

REM ============================================
REM 8. API Tests
REM ============================================
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 8. Testing API Functionality
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

echo   Testing auth register...
curl -s -X POST http://localhost:8001/auth/register -H "Content-Type: application/json" -d "{\"username\":\"testuser\",\"password\":\"testpass123\"}" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ⚠️  WARN - might already exist)

echo   Testing user create...
curl -s -X POST http://localhost:8002/users -H "Content-Type: application/json" -d "{\"name\":\"John Doe\",\"username\":\"johndoe\",\"email\":\"john@example.com\",\"password\":\"secure123\"}" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ⚠️  WARN)

echo   Testing task create...
curl -s -X POST http://localhost:8003/tasks -H "Content-Type: application/json" -d "{\"title\":\"Test Task\",\"description\":\"Testing\",\"user_id\":1}" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

echo   Testing notification send...
curl -s -X POST http://localhost:8004/notifications/notify -H "Content-Type: application/json" -d "{\"user_id\":1,\"message\":\"Test notification\",\"notification_type\":\"email\"}" >nul 2>&1
if %errorlevel% equ 0 (echo   ✅ PASS) else (echo   ❌ FAIL)

REM ============================================
REM Summary
REM ============================================
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Test Summary
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo Completed: %date% %time%
echo Log file: %LOG_FILE%
echo.
echo Services are still running for inspection.
echo To stop them, run: docker compose --profile dev down
echo.
echo If there are any errors, please send the log file: %LOG_FILE%
echo.

pause

