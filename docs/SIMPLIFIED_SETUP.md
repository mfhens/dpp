# Simplified Setup Guide

## Overview

The DPP project now has a simplified, two-mode setup:

### 1. 🚀 Local Development (Simple & Fast)
- **Use case**: Day-to-day development and debugging
- **What you get**: API with SQLite + Portal web server
- **No Docker required**
- **Command**: `.\run-local.ps1`

### 2. 🐳 Docker Deployment (Complete System)
- **Use case**: Testing full production-like environment
- **What you get**: All services (PostgreSQL, Keycloak, OPA, MinIO, ImmuDB, API, Portal)
- **Docker required**
- **Command**: `docker compose up -d`

---

## Local Development Mode

### Prerequisites
- Python (with `uv` or `pip`)
- Node.js (with `npm` or `pnpm`)

### Start Development
```powershell
# Start without sample data (empty database)
.\run-local.ps1

# Start with Lego Duck sample data
.\run-local.ps1 -Seed

# Force re-seed (overwrites existing data)
.\run-local.ps1 -Seed -Force
```

This will:
1. Install API dependencies
2. Start API with SQLite on http://localhost:8000
3. (Optional) Seed database with Lego Duck sample data
4. Install Portal dependencies  
5. Start Portal on http://localhost:3000

### Features
- ✅ Instant code reload
- ✅ Direct IDE debugging
- ✅ No container overhead
- ✅ SQLite database (no external DB needed)
- ✅ Optional Lego Duck sample data
- ⚠️ No authentication (development mode)
- ⚠️ Mock services for MinIO, ImmuDB, etc.

### Stop Development
Press `Ctrl+C` in the terminal running the script.

---

## Docker Deployment Mode

### Prerequisites
- Docker Desktop or compatible engine

### One-Time Setup
```powershell
# Create secret files
.\setup-secrets.ps1
.\verify-secrets.ps1
```

### Start All Services
```bash
docker compose up -d
```

### Features
- ✅ Full production-like environment
- ✅ PostgreSQL database
- ✅ Authentication via Keycloak
- ✅ Authorization via OPA
- ✅ Object storage (MinIO)
- ✅ Audit logging (ImmuDB)
- ⚠️ Slower startup (~1-2 minutes)
- ⚠️ Requires more resources

### Stop Services
```bash
docker compose down

# To also remove volumes (clean slate):
docker compose down -v
```

### View Logs
```bash
docker compose logs -f api
docker compose logs -f --tail=200
```

---

## Files Removed

The following redundant scripts have been removed:
- `compose.local-dev.yaml` (replaced by `run-local.ps1`)
- `setup-api.ps1` (merged into `run-local.ps1`)
- `setup-portal.ps1` (merged into `run-local.ps1`)
- `setup-local-dev.ps1` (no longer needed)
- `start-local-dev.ps1` (replaced by `run-local.ps1`)
- `stop-local-dev.ps1` (replaced by Ctrl+C)
- `reset-local-dev.ps1` (no longer needed)
- `reset-database-simple.ps1` (no longer needed)

---

## Configuration

### Local Development (.env not required)
The API automatically uses SQLite in development mode. No configuration needed.

Optional environment variables:
```bash
ENVIRONMENT=development  # Auto-set by run-local.ps1
DATABASE_URL=sqlite+pysqlite:///./dpp.db  # Default
```

### Docker Deployment (.env optional)
You can override defaults by creating a `.env` file:

```dotenv
# Database
POSTGRES_DB=dpp
POSTGRES_PORT=5432

# Services
API_PORT=8000
PORTAL_PORT=3000
KEYCLOAK_PORT=8080
OPA_PORT=8181
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001

# Public URLs (for external access)
PUBLIC_PORTAL_URL=http://localhost:3000
PUBLIC_KEYCLOAK_URL=http://localhost:8080/realms/dpp
```

---

## Switching Between Modes

### From Docker to Local
```bash
# Stop Docker services
docker compose down

# Start local development
.\run-local.ps1
```

### From Local to Docker
```powershell
# Stop local dev (Ctrl+C)

# Start Docker services
docker compose up -d
```

---

## Quick Reference

| Task | Local Dev | Docker |
|------|-----------|--------|
| **Start** | `.\run-local.ps1` | `docker compose up -d` |
| **Start with data** | `.\run-local.ps1 -Seed` | (auto-seeded) |
| **Stop** | `Ctrl+C` | `docker compose down` |
| **API URL** | http://localhost:8000 | http://localhost:8000 |
| **Portal URL** | http://localhost:3000 | http://localhost:3000 |
| **API Docs** | http://localhost:8000/docs | http://localhost:8000/docs |
| **Database** | SQLite (`dpp.db`) | PostgreSQL |
| **Auth** | Disabled | Keycloak |
| **Policy** | Mock | OPA |
| **Startup Time** | ~10 seconds | ~1-2 minutes |

---

## Troubleshooting

### Local Development Issues

**Python dependencies fail to install:**
```powershell
# Try with pip instead of uv
cd api
pip install -e .
```

**Port already in use:**
```bash
# Kill processes on ports 8000 or 3000
# Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

### Docker Issues

**Secrets not found:**
```powershell
.\setup-secrets.ps1
.\verify-secrets.ps1
```

**Services won't start:**
```bash
# Check logs
docker compose logs

# Rebuild containers
docker compose up -d --build
```

**Port conflicts:**
Edit `.env` to change port mappings.

---

## What's Next?

1. **Start developing**: Use `.\run-local.ps1` for fast iteration
2. **Test integration**: Use `docker compose up -d` to test with all services
3. **Read the docs**: Check `docs/` for architecture and design details
4. **Run tests**: See the Testing section in the main README

For more information, see the main [README.md](../Readme.md).
