# Local Development Quick Reference

## 🚀 Quick Start

```powershell
# One-time setup
.\setup-local-dev.ps1

# Daily workflow
.\start-local-dev.ps1   # Start PostgreSQL and see instructions
```

## 📋 Commands

### Initial Setup (One Time)
```powershell
.\setup-local-dev.ps1          # Complete setup
.\setup-api.ps1                # Setup API only
.\setup-portal.ps1             # Setup Portal only
```

### Daily Development
```powershell
# Start/Stop PostgreSQL
.\start-local-dev.ps1          # Start PostgreSQL
.\stop-local-dev.ps1           # Stop PostgreSQL

# Run API (Terminal 1)
cd api
.\run.ps1

# Run Portal (Terminal 2)
cd portal
.\run.ps1
```

### Docker Commands
```powershell
# PostgreSQL only
docker compose -f compose.local-dev.yaml up -d
docker compose -f compose.local-dev.yaml down
docker compose -f compose.local-dev.yaml logs -f postgres

# Full stack
docker compose up -d
docker compose down
docker compose logs -f
```

## 🌐 Access URLs

| Service | URL | Notes |
|---------|-----|-------|
| API | http://localhost:8000 | FastAPI backend |
| API Docs | http://localhost:8000/docs | Swagger UI |
| API ReDoc | http://localhost:8000/redoc | Alternative docs |
| Portal | http://localhost:3000 | Next.js frontend |
| PostgreSQL | localhost:5432 | Database |

## 🔧 Common Tasks

### Reset Database
```powershell
docker compose -f compose.local-dev.yaml down -v
docker compose -f compose.local-dev.yaml up -d
```

### View Logs
```powershell
# PostgreSQL
docker compose -f compose.local-dev.yaml logs -f postgres

# API (in API terminal)
# Logs are printed directly to console

# Portal (in Portal terminal)
# Logs are printed directly to console
```

### Database Access
```powershell
# Get credentials
$dbUser = Get-Content secrets\postgres_user.txt
$dbPass = Get-Content secrets\postgres_password.txt

# Connect with psql
psql -h localhost -U $dbUser -d dpp

# Connection string
postgresql://dpp_sx2ZMqdA:8dpvC2ubuYsbcuAU91T0h8kRwRrMZCEtZ0mAfk88@localhost:5432/dpp
```

### Update Dependencies

**API:**
```powershell
cd api
. .venv\Scripts\Activate.ps1
uv pip install -e .
```

**Portal:**
```powershell
cd portal
npm install
```

## 🐛 Troubleshooting

### PostgreSQL won't start
```powershell
# Check Docker
docker info

# View logs
docker compose -f compose.local-dev.yaml logs postgres

# Hard reset
docker compose -f compose.local-dev.yaml down -v
docker compose -f compose.local-dev.yaml up -d
```

### API won't start
```powershell
# Check PostgreSQL is running
docker compose -f compose.local-dev.yaml ps

# Check virtual environment
cd api
. .venv\Scripts\Activate.ps1
python --version  # Should be 3.13+

# Reinstall dependencies
uv pip install -e .
```

### Portal won't start
```powershell
# Check Node version
node --version  # Should be 20+

# Reinstall dependencies
cd portal
Remove-Item -Recurse -Force node_modules
npm install
```

### Port conflicts
Edit `.env.local` and change ports:
```
API_PORT=8001
PORTAL_PORT=3001
POSTGRES_PORT=5433
```

## 📁 Important Files

| File | Purpose |
|------|---------|
| `compose.local-dev.yaml` | PostgreSQL-only Docker Compose |
| `.env.local` | Local development environment variables |
| `LOCAL_DEV.md` | Complete local development guide |
| `api/.env` | API environment configuration |
| `api/run.ps1` | Run API script |
| `portal/.env.local` | Portal environment configuration |
| `portal/run.ps1` | Run Portal script |
| `secrets/*.txt` | Secret files (gitignored) |

## 💡 Tips

1. **Use separate terminals** for API and Portal to see logs clearly
2. **Code auto-reloads** - API and Portal will reload on file changes
3. **Check health** - Visit http://localhost:8000/docs to check API health
4. **Database seeding** - Runs automatically when PostgreSQL starts fresh
5. **Clean slate** - Use `down -v` to reset database completely

## 🔄 Switching Between Modes

### From Full Docker to Local Dev
```powershell
docker compose down
docker compose -f compose.local-dev.yaml up -d
cd api && .\run.ps1
cd portal && .\run.ps1
```

### From Local Dev to Full Docker
```powershell
# Stop local services (Ctrl+C in terminals)
docker compose -f compose.local-dev.yaml down
docker compose up -d
```

## 📚 More Information

- **Complete guide**: See `LOCAL_DEV.md`
- **Architecture**: See `Readme.md`
- **API code**: `api/dpp_api/main.py`
- **Portal code**: `portal/app/`
