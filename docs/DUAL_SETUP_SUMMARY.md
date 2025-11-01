# Dual Setup Summary

## ✅ What's Been Added

Your DPP API now fully supports dual deployment modes:

### 1. **Configuration Layer** (`api/dpp_api/config.py`)
- ✅ Pydantic-based settings with environment profiles
- ✅ Automatic database URL resolution
- ✅ Secret file handling for Docker
- ✅ Environment-aware service mocking

### 2. **Updated Database Layer** (`api/dpp_api/models.py`)
- ✅ Uses new config system
- ✅ Seamless SQLite/PostgreSQL switching
- ✅ No code changes needed - fully automatic

### 3. **Mock Services** (`api/dpp_api/services/mocks.py`)
- ✅ MockMinIOService - in-memory object storage
- ✅ MockImmuDBService - stdout audit logging
- ✅ MockOPAService - always-allow policy
- ✅ MockAuthService - no-op authentication

### 4. **Convenience Scripts**

**Local Development:**
- `api/run-local-dev.ps1` - Start with SQLite, no Docker

**Docker Production:**
- `api/run-docker.ps1` - Start full stack with PostgreSQL

**Testing:**
- `api/test-dual-mode.ps1` - Test both modes automatically

### 5. **Documentation**
- `DUAL_SETUP_GUIDE.md` - Comprehensive guide
- `DUAL_SETUP_SUMMARY.md` - This file (quick reference)

---

## 🚀 Quick Start

### Local Demo (No Docker)
```powershell
cd api
.\run-local-dev.ps1
# Open http://localhost:8000/docs
```

### Production (Docker)
```powershell
docker compose up
# Open http://localhost:8000/docs
```

---

## 🎯 When to Use Each Mode

| Scenario | Use Mode | Why |
|----------|----------|-----|
| Quick demo | **Local** | Starts in 1 second |
| Learning API | **Local** | No setup complexity |
| Debugging models | **Local** | Direct file access |
| Integration tests | **Docker** | Full stack needed |
| Production deploy | **Docker** | PostgreSQL required |
| Security testing | **Docker** | Real auth needed |

---

## 🔧 How It Works

### Database Selection
```python
# Automatic based on ENVIRONMENT variable
if ENVIRONMENT == "development":
    → SQLite (./dpp.db)
else:
    → PostgreSQL (from DATABASE_URL)
```

### Service Mocking
```python
# In config.py
if settings.environment == "development":
    → Mock services (no external deps)
else:
    → Real services (MinIO, Keycloak, etc.)
```

---

## 📦 Dependencies

### Added to `pyproject.toml`
```toml
pydantic-settings>=2.0.0  # NEW: Environment-based config
```

All other dependencies work with both modes:
- `sqlalchemy` - Supports SQLite AND PostgreSQL
- `psycopg` - Only loaded for PostgreSQL
- `fastapi`, `uvicorn` - Mode-independent

---

## 🔄 Migration Path

### Existing Docker Setup
**No changes needed!** Your current `compose.yaml` and secrets still work.

### New Local Dev Option
**Just run:**
```powershell
cd api
.\run-local-dev.ps1
```

No configuration needed - SQLite mode auto-detected.

---

## 🧪 Testing

```powershell
# Test local mode
cd api
.\test-dual-mode.ps1 -SkipDocker

# Test Docker mode (services must be running)
docker compose up -d
.\test-dual-mode.ps1 -SkipLocal

# Test both
.\test-dual-mode.ps1
```

---

## 📊 Comparison

| Feature | Local Dev | Docker |
|---------|-----------|--------|
| **Startup** | ~1s | ~30s |
| **Memory** | 50 MB | 1+ GB |
| **Database** | SQLite file | PostgreSQL container |
| **Auth** | Disabled | Keycloak OIDC |
| **Storage** | Mock | MinIO |
| **Audit** | Stdout | ImmuDB |
| **Policy** | Mock | OPA |

---

## 🎓 Next Steps

### For Presentations/Demos
1. Use local dev mode
2. Show API docs at `/docs`
3. Create DPPs without auth
4. Show SQLite file (`dpp.db`)

### For Development
1. Start local dev: `.\run-local-dev.ps1`
2. Make code changes
3. Watch hot reload
4. Test with Docker before committing

### For Production
1. Use Docker compose
2. Configure secrets properly
3. Enable all security features
4. Monitor with real services

---

## 🐛 Troubleshooting

### Local Mode Issues

**Port conflict:**
```powershell
.\run-local-dev.ps1 -Port 8001
```

**SQLite locked:**
```powershell
Remove-Item api/dpp.db
```

### Docker Mode Issues

**Services not starting:**
```powershell
.\verify-secrets.ps1
docker compose up --build
```

**Database connection error:**
```powershell
# Check PostgreSQL health
docker compose ps postgres
docker compose logs postgres
```

---

## 📝 Code Changes Required: NONE

✨ **Your existing code works in both modes!**

The dual setup is achieved through:
- Configuration abstraction
- Environment detection
- Service mocking
- Database URL resolution

No API endpoint changes needed.
No business logic changes needed.
No schema changes needed.

---

## ✅ Summary

**Question**: Can I run dual setup?
**Answer**: **YES! It's already configured!**

- ✅ PostgreSQL + Docker → Production ready
- ✅ SQLite + Terminal → Demo ready
- ✅ Same codebase → Zero duplication
- ✅ Zero config → Auto-detected

**Just pick your mode and run!** 🚀
