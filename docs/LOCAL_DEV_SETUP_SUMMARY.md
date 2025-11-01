# Local Development Setup - Summary

## What Was Created

The DPP project now has complete support for running the API and Portal locally from the command line, with only PostgreSQL running in Docker.

## New Files

### Configuration Files
1. **`compose.local-dev.yaml`** - Docker Compose file that runs only PostgreSQL
2. **`.env.local`** - Environment variables for local development

### Setup Scripts
3. **`setup-local-dev.ps1`** - Master setup script (runs all setup steps)
4. **`setup-api.ps1`** - Sets up Python environment and API configuration
5. **`setup-portal.ps1`** - Sets up Node.js environment and Portal configuration

### Runtime Scripts
6. **`start-local-dev.ps1`** - Starts PostgreSQL and shows instructions
7. **`stop-local-dev.ps1`** - Stops PostgreSQL
8. **`api/run.ps1`** - Runs the API server (created by setup-api.ps1)
9. **`portal/run.ps1`** - Runs the Portal server (created by setup-portal.ps1)

### Documentation
10. **`LOCAL_DEV.md`** - Complete local development guide
11. **`QUICK_REFERENCE.md`** - Quick reference card for common commands
12. **`Readme.md`** - Updated to reference local development options

## How to Use

### First Time Setup

Run the master setup script once:

```powershell
.\setup-local-dev.ps1
```

This will:
1. Create/verify secrets
2. Start PostgreSQL in Docker
3. Setup Python environment for API
4. Setup Node.js environment for Portal

### Daily Workflow

1. **Start PostgreSQL** (one time per session):
   ```powershell
   .\start-local-dev.ps1
   ```

2. **Run API** (Terminal 1):
   ```powershell
   cd api
   .\run.ps1
   ```

3. **Run Portal** (Terminal 2):
   ```powershell
   cd portal
   .\run.ps1
   ```

### Access Your Services

- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Portal**: http://localhost:3000

## Benefits

### 🚀 Faster Development
- Code changes reload instantly (no Docker rebuild)
- Faster startup times
- Less resource usage

### 🐛 Easier Debugging
- Direct IDE debugging support
- Clear, uncontainerized logs
- Easy to run tests and linters

### 🔧 Better Developer Experience
- Native Python/Node.js development
- Use your favorite tools directly
- Easier to install and update dependencies

### 🎯 Flexibility
- Run only what you need
- Mix and match (e.g., API local, Portal in Docker)
- Easy to switch between modes

## File Structure

```
dpp/
├── compose.local-dev.yaml          # PostgreSQL-only compose
├── .env.local                      # Local dev environment vars
├── setup-local-dev.ps1            # Master setup script
├── setup-api.ps1                  # API setup script
├── setup-portal.ps1               # Portal setup script
├── start-local-dev.ps1            # Start PostgreSQL
├── stop-local-dev.ps1             # Stop PostgreSQL
├── LOCAL_DEV.md                   # Complete guide
├── QUICK_REFERENCE.md             # Quick commands
├── Readme.md                      # Updated main readme
├── api/
│   ├── .env                       # API config (created by setup)
│   ├── run.ps1                    # Run API (created by setup)
│   └── .venv/                     # Python virtual env (created by setup)
└── portal/
    ├── .env.local                 # Portal config (created by setup)
    ├── run.ps1                    # Run Portal (created by setup)
    └── node_modules/              # Node deps (created by setup)
```

## Environment Variables

### API (api/.env)
- `DATABASE_URL` - PostgreSQL connection string
- `MINIO_ENDPOINT`, `OIDC_ISSUER_URL`, `OPA_URL`, etc.
- Points to secret files in `secrets/` directory

### Portal (portal/.env.local)
- `NEXT_PUBLIC_API_BASE` - API URL (http://localhost:8000)
- `NEXT_PUBLIC_OIDC_ISSUER` - Keycloak URL
- `NEXTAUTH_SECRET` - Portal auth secret

## Secrets Management

All secrets are stored in the `secrets/` directory and referenced by the local scripts:
- `database_url.txt` - Full PostgreSQL connection string
- `jwt_secret.txt` - JWT signing secret
- `encryption_key.txt` - Encryption key
- `nextauth_secret.txt` - Portal auth secret
- And more...

These files are created by `setup-secrets.ps1` and are gitignored.

## Switching Modes

### Local Dev → Full Docker
```powershell
docker compose -f compose.local-dev.yaml down
docker compose up -d
```

### Full Docker → Local Dev
```powershell
docker compose down
.\start-local-dev.ps1
# Then run API and Portal in separate terminals
```

## Common Commands

See `QUICK_REFERENCE.md` for a complete list of commands.

Quick essentials:
```powershell
# Setup (once)
.\setup-local-dev.ps1

# Daily
.\start-local-dev.ps1
cd api && .\run.ps1       # Terminal 1
cd portal && .\run.ps1    # Terminal 2

# Stop
.\stop-local-dev.ps1      # Stops PostgreSQL
# Ctrl+C in API terminal
# Ctrl+C in Portal terminal

# Reset database
docker compose -f compose.local-dev.yaml down -v
docker compose -f compose.local-dev.yaml up -d
```

## Troubleshooting

See `LOCAL_DEV.md` for detailed troubleshooting.

Common issues:
1. **PostgreSQL not starting**: Check Docker Desktop is running
2. **API not starting**: Check virtual environment is activated
3. **Portal not starting**: Check Node.js version (needs 20+)
4. **Port conflicts**: Edit `.env.local` to change ports

## Notes

- The setup scripts are idempotent - safe to run multiple times
- API uses `uv` for Python package management (faster than pip)
- Portal uses `npm` (can also use `pnpm` or `yarn`)
- All scripts are PowerShell-based for Windows compatibility
- Scripts can be adapted for bash on Linux/Mac

## Next Steps

1. Run `.\setup-local-dev.ps1` to get started
2. Follow the on-screen instructions
3. Access the API docs at http://localhost:8000/docs
4. Start building!

For more details:
- **Complete guide**: `LOCAL_DEV.md`
- **Quick reference**: `QUICK_REFERENCE.md`
- **Main readme**: `Readme.md`
