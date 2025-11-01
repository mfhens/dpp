# DPP API Dual Setup Guide

The DPP API supports two deployment modes to match different use cases:

## 🎯 Overview

| Mode | Database | Services | Auth | Use Case |
|------|----------|----------|------|----------|
| **Local Development** | SQLite | Mocked/Disabled | Optional | Quick demos, local dev, testing |
| **Docker Production** | PostgreSQL | Full Stack | Required | Production, integration testing |

---

## 🚀 Mode 1: Local Development (SQLite + Terminal)

### Features
- ✅ **SQLite database** - No PostgreSQL installation needed
- ✅ **No Docker required** - Run directly with Python/uv
- ✅ **Mock services** - MinIO, ImmuDB, OPA, Keycloak not required
- ✅ **No authentication** - Simplified for demos
- ✅ **Hot reload** - Code changes apply instantly
- ✅ **Single command** - Start in seconds

### Quick Start

```powershell
# Navigate to API directory
cd api

# Run in local development mode
.\run-local-dev.ps1
```

Or manually:
```powershell
cd api
$env:ENVIRONMENT = "development"
uv run uvicorn dpp_api.main:app --reload
```

### Configuration

The API automatically detects development mode when `DATABASE_URL` is not set.

**Environment Variables** (optional):
```powershell
$env:ENVIRONMENT = "development"        # Enables SQLite + mock services
$env:SQL_ECHO = "1"                     # Show SQL queries (debugging)
$env:API_PORT = "8000"                  # Change port (default: 8000)
```

### Database Location
- SQLite file: `./dpp.db` (created automatically)
- Schema initialized on first startup
- Can delete `dpp.db` to reset database

### Testing Endpoints

```powershell
# API documentation (interactive)
http://localhost:8000/docs

# Health check
curl http://localhost:8000/

# Create DPP (no auth required in dev mode)
curl -X POST http://localhost:8000/dpp `
  -H "Content-Type: application/json" `
  -d '{
    "product_id": "urn:example:product:123",
    "model": "X100",
    "payload": {
      "id": "https://example.org/dpp/test-001",
      "modelNumber": "X100",
      "manufacturer": {"name": "ACME Corp"}
    }
  }'
```

### When to Use
- 🎓 **Demos and presentations**
- 🧪 **Local development and testing**
- 📚 **Learning the API**
- 🐛 **Debugging without container complexity**
- 🔧 **Schema/model changes**

---

## 🐳 Mode 2: Docker Production (PostgreSQL + Full Stack)

### Features
- ✅ **PostgreSQL database** - Production-grade RDBMS
- ✅ **Full authentication** - Keycloak OIDC
- ✅ **Object storage** - MinIO for attachments
- ✅ **Audit logging** - ImmuDB immutable log
- ✅ **Policy enforcement** - Open Policy Agent (OPA)
- ✅ **Complete isolation** - All services containerized

### Quick Start

```powershell
# From project root
.\setup-secrets.ps1           # First time only
.\setup-local-dev.ps1         # First time only

# Start full stack
docker compose up

# Or using the helper script
.\api\run-docker.ps1
```

### Configuration

Uses environment variables from `compose.yaml` and secrets from `secrets/` directory.

**Key Environment Variables**:
```yaml
ENVIRONMENT: docker                    # Enables PostgreSQL + full services
DATABASE_URL: postgresql+psycopg://... # Read from secrets/database_url.txt
OIDC_ISSUER_URL: http://keycloak:8080/realms/dpp
MINIO_ENDPOINT: http://minio:9000
IMMUDB_ADDR: immudb:3322
OPA_URL: http://opa:8181/v1/data/dpp/allow
```

### Service Endpoints

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| API | 8000 | http://localhost:8000/docs | DPP REST API |
| Portal | 3000 | http://localhost:3000 | Web UI |
| Keycloak | 8080 | http://localhost:8080 | Identity Provider |
| MinIO Console | 9001 | http://localhost:9001 | Object Storage UI |
| PostgreSQL | 5432 | localhost:5432 | Database |
| ImmuDB | 3322 | localhost:3322 | Audit Log |
| OPA | 8181 | localhost:8181 | Policy Engine |

### Testing with Authentication

```powershell
# 1. Get access token from Keycloak
$token = (curl -X POST http://localhost:8080/realms/dpp/protocol/openid-connect/token `
  -d "client_id=dpp-api" `
  -d "client_secret=<from secrets/oidc_client_secret.txt>" `
  -d "grant_type=client_credentials" | ConvertFrom-Json).access_token

# 2. Call API with token
curl -X POST http://localhost:8000/dpp `
  -H "Authorization: Bearer $token" `
  -H "Content-Type: application/json" `
  -d '{...}'
```

### Database Management

```powershell
# Reset database
.\reset-database-simple.ps1

# Connect to PostgreSQL
docker compose exec postgres psql -U $(cat secrets/postgres_user.txt) -d dpp

# View logs
docker compose logs -f postgres

# Backup database
docker compose exec postgres pg_dump -U $(cat secrets/postgres_user.txt) dpp > backup.sql
```

### When to Use
- 🏭 **Production deployments**
- 🔒 **Security testing with real auth**
- 🔗 **Integration testing with full stack**
- 📊 **Performance testing with PostgreSQL**
- 🎭 **Demo of complete system**

---

## 🔄 Switching Between Modes

### From Docker to Local Dev

```powershell
# Stop Docker services
docker compose down

# Start local dev
cd api
.\run-local-dev.ps1
```

**Data Note**: SQLite and PostgreSQL are separate databases. Data is not shared.

### From Local Dev to Docker

```powershell
# Stop local dev (Ctrl+C)

# Start Docker
docker compose up
```

---

## 📝 Configuration Details

### Config Class (`api/dpp_api/config.py`)

The `Settings` class uses `pydantic-settings` to manage environment-based configuration:

```python
from dpp_api.config import settings

# Automatically resolves based on ENVIRONMENT variable
db_url = settings.resolved_database_url

# development: sqlite+pysqlite:///./dpp.db
# docker/production: Uses DATABASE_URL or DATABASE_URL_FILE
```

### Environment Profiles

| Profile | `ENVIRONMENT` | Database | Auth | Services |
|---------|---------------|----------|------|----------|
| **Development** | `development` | SQLite | Disabled | Mocked |
| **Docker** | `docker` | PostgreSQL | Enabled | Real |
| **Production** | `production` | PostgreSQL | Enabled | Real |

### Database URL Resolution Priority

1. **`DATABASE_URL_FILE`** - Path to file with connection string (Docker secrets)
2. **`DATABASE_URL`** - Direct connection string (environment variable)
3. **Environment default**:
   - `development`: `sqlite+pysqlite:///./dpp.db`
   - `docker`/`production`: Raises error (must be explicitly set)

---

## 🧪 Testing Both Modes

### Integration Test Script

```powershell
# Test local dev mode
cd api
$env:ENVIRONMENT = "development"
uv run pytest tests/

# Test docker mode
docker compose up -d
Start-Sleep -Seconds 30  # Wait for services
uv run pytest tests/ --integration
docker compose down
```

---

## 🎛️ Advanced Configuration

### Custom SQLite Location

```powershell
$env:DATABASE_URL = "sqlite+pysqlite:///c:/data/my-dpp.db"
.\run-local-dev.ps1
```

### Enable SQL Query Logging

```powershell
$env:SQL_ECHO = "1"  # Development
# or in compose.yaml for Docker
SQL_ECHO: "1"
```

### Mock Service Stubs

In development mode, service dependencies are automatically disabled:

- **Auth**: `settings.require_authentication == False`
- **MinIO**: Operations succeed without actual storage
- **ImmuDB**: Audit logs are no-ops
- **OPA**: Policy checks always pass

---

## 📊 Performance Comparison

| Metric | Local Dev (SQLite) | Docker (PostgreSQL) |
|--------|-------------------|---------------------|
| Startup Time | ~1 second | ~30 seconds |
| Memory Usage | ~50 MB | ~1 GB (all services) |
| Disk Space | ~5 MB | ~500 MB+ |
| Request Latency | <10ms | <50ms |
| Concurrent Users | 1-5 | 100+ |

---

## 🐛 Troubleshooting

### Local Dev Issues

**Problem**: `ModuleNotFoundError`
```powershell
# Solution: Install dependencies
cd api
uv sync
```

**Problem**: Port 8000 already in use
```powershell
# Solution: Change port
.\run-local-dev.ps1 -Port 8001
```

**Problem**: SQLite locked
```powershell
# Solution: Close other connections or delete db
Remove-Item dpp.db
```

### Docker Issues

**Problem**: Services won't start
```powershell
# Solution: Check secrets exist
.\verify-secrets.ps1

# Rebuild containers
docker compose up --build
```

**Problem**: Database connection refused
```powershell
# Solution: Wait for PostgreSQL health check
docker compose ps  # Check status
docker compose logs postgres  # Check logs
```

**Problem**: Port conflicts
```powershell
# Solution: Change ports in compose.yaml or .env
$env:API_PORT = "8001"
$env:POSTGRES_PORT = "5433"
docker compose up
```

---

## 📚 Additional Resources

- **API Documentation**: [api/README.md](api/README.md)
- **Local Dev Setup**: [LOCAL_DEV.md](LOCAL_DEV.md)
- **Architecture**: [LOCAL_DEV_ARCHITECTURE.md](LOCAL_DEV_ARCHITECTURE.md)
- **Quick Reference**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

---

## ✅ Summary

| Want to... | Use Mode | Command |
|------------|----------|---------|
| Quick demo | Local Dev | `cd api && .\run-local-dev.ps1` |
| Test changes fast | Local Dev | `cd api && .\run-local-dev.ps1` |
| Full integration test | Docker | `docker compose up` |
| Deploy to production | Docker | `docker compose up -d` |
| Learn the API | Local Dev | `cd api && .\run-local-dev.ps1` |

**Bottom line**: Local dev for speed, Docker for completeness! 🎯
