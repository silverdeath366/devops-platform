# 🧪 How to Run the Comprehensive Test Script

This guide explains how to run the comprehensive test script that verifies everything is working correctly.

---

## 📋 What the Test Script Does

The test script performs **over 60 automated tests** including:

1. ✅ **Prerequisites Check** - Docker, Python, Make
2. ✅ **Project Structure** - All required files and directories
3. ✅ **Service Files** - Validates each service structure
4. ✅ **Docker Builds** - Builds all 4 service images
5. ✅ **Service Startup** - Starts services with Docker Compose
6. ✅ **Container Health** - Verifies all containers are running
7. ✅ **Health Endpoints** - Tests `/health`, `/healthz`, `/ready`
8. ✅ **Metrics Endpoints** - Tests `/metrics` for Prometheus
9. ✅ **API Functionality** - Tests all CRUD operations
10. ✅ **Python Unit Tests** - Runs pytest for all services
11. ✅ **Docker Compose Status** - Validates service state
12. ✅ **Container Logs** - Checks for errors in logs

---

## 🚀 Running on Linux/Mac/WSL

### Step 1: Make the script executable

```bash
chmod +x test-everything.sh
```

### Step 2: Run the test script

```bash
./test-everything.sh
```

### Alternative: Run with bash explicitly

```bash
bash test-everything.sh
```

---

## 🪟 Running on Windows

### Option 1: Use WSL (Recommended)

If you have Windows Subsystem for Linux (WSL):

```bash
wsl
cd /mnt/c/path/to/devops-platform-broken
bash test-everything.sh
```

### Option 2: Use Windows Batch Script

```cmd
test-everything.bat
```

### Option 3: Use Git Bash

If you have Git for Windows installed:

```bash
bash test-everything.sh
```

---

## 📊 Understanding the Output

### Successful Test Output

```
✅ PASS - Docker installation
✅ PASS - Docker Compose installation
✅ PASS - Python installation
✅ PASS - Building auth Docker image
✅ PASS - auth service /health endpoint
✅ PASS - Auth: Register user
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Tests:  62
Passed:       62
Failed:       0
Pass Rate:    100%

╔════════════════════════════════════════════╗
║           ALL TESTS PASSED! 🎉             ║
╚════════════════════════════════════════════╝
```

### Failed Test Output

```
❌ FAIL - auth service /health endpoint
    Error: HTTP 000

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Tests:  62
Passed:       58
Failed:       4
Pass Rate:    93%

╔════════════════════════════════════════════╗
║         SOME TESTS FAILED ❌                ║
╚════════════════════════════════════════════╝

Please review the log file: test-results-YYYYMMDD-HHMMSS.log
```

---

## 📝 Log Files

The script creates a detailed log file named:
```
test-results-YYYYMMDD-HHMMSS.log
```

Example: `test-results-20241109-143025.log`

This log contains:
- Detailed output of every test
- Docker build logs
- Container logs
- HTTP responses
- Error messages and stack traces

---

## 🐛 If Tests Fail

### Step 1: Review the log file

```bash
cat test-results-*.log
# or
less test-results-*.log
# or on Windows
type test-results-*.log
```

### Step 2: Copy the log file content

```bash
# Linux/Mac
cat test-results-*.log | pbcopy  # Mac
cat test-results-*.log | xclip   # Linux

# Windows
type test-results-*.log | clip
```

### Step 3: Share the error output

Provide the following information:

1. **The complete log file** (or at least the failed sections)
2. **Your operating system** (Windows/Linux/Mac)
3. **Docker version**: `docker --version`
4. **Python version**: `python --version`
5. **Any additional context** about your setup

---

## 🔧 Common Issues and Quick Fixes

### Issue 1: "Docker not found"

**Solution:**
```bash
# Install Docker
# Linux
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Mac
brew install --cask docker

# Windows
# Download Docker Desktop from docker.com
```

### Issue 2: "Permission denied"

**Solution:**
```bash
# Linux/Mac - Make script executable
chmod +x test-everything.sh

# Or run with bash
bash test-everything.sh

# Add user to docker group (Linux)
sudo usermod -aG docker $USER
# Then log out and back in
```

### Issue 3: "Port already in use"

**Solution:**
```bash
# Stop existing services
docker compose down

# Or kill processes on ports
# Linux/Mac
sudo lsof -ti:8001 | xargs kill -9
sudo lsof -ti:8002 | xargs kill -9
sudo lsof -ti:8003 | xargs kill -9
sudo lsof -ti:8004 | xargs kill -9

# Windows
netstat -ano | findstr :8001
taskkill /PID <PID> /F
```

### Issue 4: "Container fails to start"

**Solution:**
```bash
# Check container logs
docker logs devops-auth
docker logs devops-user
docker logs devops-task
docker logs devops-notification

# Rebuild containers
docker compose --profile dev down
docker compose --profile dev up -d --build
```

### Issue 5: "curl: command not found"

**Solution:**
```bash
# Linux
sudo apt-get install curl

# Mac
brew install curl

# Windows
# Download from https://curl.se/windows/
# Or use WSL
```

---

## 🎯 Manual Verification (If Script Fails)

If the automated script has issues, you can manually verify:

### 1. Check Docker

```bash
docker --version
docker compose version
docker ps
```

### 2. Build Services

```bash
docker build -t test-auth services/auth
docker build -t test-user services/user
docker build -t test-task services/task
docker build -t test-notification services/notification
```

### 3. Start Services

```bash
docker compose --profile dev up -d
docker compose ps
```

### 4. Test Endpoints

```bash
# Health checks
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:8004/health

# Metrics
curl http://localhost:8001/metrics
curl http://localhost:8002/metrics
curl http://localhost:8003/metrics
curl http://localhost:8004/metrics

# API tests
curl -X POST http://localhost:8001/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}'

curl -X POST http://localhost:8002/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John","username":"john","email":"john@test.com","password":"test123"}'
```

### 5. Run Python Tests

```bash
cd services/auth
python -m pytest tests/ -v
cd ../..

cd services/user
python -m pytest tests/ -v
cd ../..
```

---

## 📤 Sending Results for Debug

When sending test results, please include:

1. **Complete log file**: `test-results-*.log`
2. **Docker version**:
   ```bash
   docker --version
   docker compose version
   ```
3. **Python version**:
   ```bash
   python --version
   ```
4. **Operating system**:
   ```bash
   # Linux
   uname -a
   cat /etc/os-release
   
   # Mac
   sw_vers
   
   # Windows
   systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
   ```
5. **Container status**:
   ```bash
   docker ps -a
   docker compose ps
   ```
6. **Container logs** (if specific service fails):
   ```bash
   docker logs devops-auth > auth-logs.txt 2>&1
   docker logs devops-user > user-logs.txt 2>&1
   docker logs devops-task > task-logs.txt 2>&1
   docker logs devops-notification > notification-logs.txt 2>&1
   ```

---

## ✅ Success Checklist

After running the test script, you should see:

- [ ] All prerequisites installed (Docker, Python)
- [ ] All project files present
- [ ] All 4 Docker images built successfully
- [ ] All 4 containers running
- [ ] All health endpoints responding (200 OK)
- [ ] All metrics endpoints responding
- [ ] All API operations working
- [ ] All Python tests passing
- [ ] No errors in container logs

---

## 🆘 Still Having Issues?

If you're still experiencing problems:

1. **Review the log file carefully** - it contains detailed error messages
2. **Check Docker Desktop is running** (on Windows/Mac)
3. **Ensure no port conflicts** - ports 8001-8004 must be free
4. **Try a clean start**:
   ```bash
   docker compose down -v
   docker system prune -a
   ./test-everything.sh
   ```
5. **Provide the complete log file** - I'll help you debug it!

---

**Ready to test? Run `./test-everything.sh` or `test-everything.bat` and send me the output!** 🚀

