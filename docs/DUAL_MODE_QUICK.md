# 🎯 DPP API - Quick Mode Reference

## Local Development (SQLite)
```powershell
cd api
.\run-local-dev.ps1
```
- ✅ SQLite database (`./dpp.db`)
- ✅ No Docker needed
- ✅ No authentication
- ✅ Starts in ~1 second
- 🌐 http://localhost:8000/docs

## Docker Production (PostgreSQL)
```powershell
docker compose up
```
- ✅ PostgreSQL database
- ✅ Full authentication
- ✅ All services (MinIO, Keycloak, etc.)
- ✅ Production-ready
- 🌐 http://localhost:8000/docs

## Switch Between Modes
```powershell
# Stop current mode (Ctrl+C or docker compose down)
# Start other mode (commands above)
```

## Test Both Modes
```powershell
cd api
.\test-dual-mode.ps1
```

---

**Read more**: `DUAL_SETUP_GUIDE.md` | `DUAL_SETUP_SUMMARY.md`
