# Local Development Guide

This guide explains how to run the API and Portal locally from the command line, with only PostgreSQL running in Docker.

## Prerequisites

- **Python 3.13+** with `uv` package manager
- **Node.js 20+** with `npm` or `pnpm`
- **Docker Desktop** (for PostgreSQL only)
- **PowerShell** (Windows) or compatible shell

## Quick Start

### 1. Setup Secrets

First, ensure your secrets are configured:

```powershell
.\setup-secrets.ps1
.\verify-secrets.ps1
```

### 2. Start PostgreSQL Only

Use the local development compose file:

```powershell
docker compose -f compose.local-dev.yaml up -d
```

Check PostgreSQL is running:

```powershell
docker compose -f compose.local-dev.yaml ps
docker compose -f compose.local-dev.yaml logs postgres
```

### 3. Setup and Run the API

Navigate to the API directory and install dependencies:

```powershell
cd api

# Create virtual environment and install dependencies using uv
uv venv
.venv\Scripts\Activate.ps1  # On Windows
# source .venv/bin/activate  # On Linux/Mac

# Install dependencies
uv pip install -e .
```

Create a local configuration file for secrets:

```powershell
# In api/ directory, create a .env file
Copy-Item ..\.env.local .env
```

Run the API server:

```powershell
# Make sure you're in the api/ directory with venv activated
uvicorn dpp_api.main:app --host localhost --port 8000 --reload
```

The API will be available at `http://localhost:8000`

### 4. Setup and Run the Portal

Open a new terminal window and navigate to the portal directory:

```powershell
cd portal

# Install dependencies
npm install
# or
pnpm install
```

Create a local environment file:

```powershell
# In portal/ directory, create a .env.local file
Copy-Item ..\.env.local .env.local
```

Run the development server:

```powershell
npm run dev
# or
pnpm dev
```

The Portal will be available at `http://localhost:3000`

## Environment Configuration

### API Environment Variables

The API needs these environment variables (configured in `.env`):

- `DATABASE_URL` - PostgreSQL connection string
- `MINIO_ENDPOINT` - Object storage endpoint
- `OIDC_ISSUER_URL` - Keycloak realm URL
- `OIDC_AUDIENCE` - API audience
- `OPA_URL` - Policy engine URL
- `IMMUDB_ADDR` - Audit database address
- `JWT_SECRET_FILE` - Path to JWT secret file
- `ENCRYPTION_KEY_FILE` - Path to encryption key file

### Portal Environment Variables

The Portal needs these environment variables (configured in `.env.local`):

- `NEXT_PUBLIC_API_BASE` - API base URL
- `NEXT_PUBLIC_OIDC_ISSUER` - Keycloak realm URL
- `NEXT_PUBLIC_CLIENT_ID` - OIDC client ID
- `NEXTAUTH_URL` - NextAuth URL
- `NEXTAUTH_SECRET_FILE` - Path to NextAuth secret file

## Reading Secrets

When running locally, you'll need to read secrets from files. Here's how to load them:

### Python (API)

```python
from pathlib import Path

def read_secret(name: str) -> str:
    secret_path = Path(__file__).parent.parent / "secrets" / f"{name}.txt"
    return secret_path.read_text().strip()

# Usage
DATABASE_URL = os.getenv("DATABASE_URL") or read_secret("database_url")
```

### TypeScript (Portal)

```typescript
import { readFileSync } from 'fs';
import { join } from 'path';

function readSecret(name: string): string {
  const secretPath = join(__dirname, '..', 'secrets', `${name}.txt`);
  return readFileSync(secretPath, 'utf-8').trim();
}

// Usage
const nextAuthSecret = process.env.NEXTAUTH_SECRET || readSecret('nextauth_secret');
```

## Development Workflow

### Typical Development Flow

1. **Start PostgreSQL**: `docker compose -f compose.local-dev.yaml up -d`
2. **Run API**: `cd api && uvicorn dpp_api.main:app --reload`
3. **Run Portal**: `cd portal && npm run dev`
4. **Make changes** to code - servers will auto-reload
5. **Test** your changes at http://localhost:3000

### Database Management

Reset the database:

```powershell
# Stop and remove volumes
docker compose -f compose.local-dev.yaml down -v

# Start fresh (seed scripts will run again)
docker compose -f compose.local-dev.yaml up -d
```

View database logs:

```powershell
docker compose -f compose.local-dev.yaml logs -f postgres
```

Connect to PostgreSQL directly:

```powershell
# Get credentials from secrets
$dbUser = Get-Content secrets\postgres_user.txt
$dbPass = Get-Content secrets\postgres_password.txt

# Connect using psql (if installed)
psql -h localhost -U $dbUser -d dpp

# Or use a GUI tool like pgAdmin, DBeaver, etc.
```

## Running with Full Services

If you need other services (Keycloak, OPA, MinIO, ImmuDB), you have options:

### Option 1: Use Full Docker Compose

```powershell
# Stop local dev compose
docker compose -f compose.local-dev.yaml down

# Start full stack
docker compose up -d

# Stop API and Portal containers to run them locally
docker compose stop api portal
```

### Option 2: Run Additional Services Individually

```powershell
# Keep PostgreSQL from local-dev compose
docker compose -f compose.local-dev.yaml up -d postgres

# Start only the services you need from main compose
docker compose up -d keycloak opa minio immudb
```

## Troubleshooting

### API won't start

- Check PostgreSQL is running: `docker compose -f compose.local-dev.yaml ps`
- Check DATABASE_URL is correct in `.env`
- Check secrets files exist and are readable
- Check Python virtual environment is activated

### Portal won't start

- Check Node.js version: `node --version` (should be 20+)
- Clear node_modules and reinstall: `rm -r node_modules && npm install`
- Check API is running at http://localhost:8000
- Check `.env.local` file exists with correct variables

### Database connection issues

- Verify PostgreSQL is healthy: `docker compose -f compose.local-dev.yaml logs postgres`
- Check port 5432 is not already in use
- Verify credentials match secrets files
- Try connecting with psql to confirm connectivity

### Port conflicts

If ports are already in use, update them in `.env.local`:

```
API_PORT=8001
PORTAL_PORT=3001
POSTGRES_PORT=5433
```

And restart the services with the new ports.

## Additional Tools

### API Documentation

With the API running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### Database Migrations

If you need to run migrations or seed data manually:

```powershell
cd api
python -m dpp_api.db migrate
python -m dpp_api.db seed
```

## Best Practices

1. **Use separate terminals** for API and Portal to see logs clearly
2. **Keep secrets secure** - never commit secrets files
3. **Use virtual environments** for Python to avoid dependency conflicts
4. **Restart services** after changing environment variables
5. **Check logs** when things don't work - errors are usually informative
6. **Use --reload** flags during development for auto-restart on code changes

## Stopping Services

Stop all local services:

```powershell
# Stop PostgreSQL
docker compose -f compose.local-dev.yaml down

# Stop API: Ctrl+C in the API terminal
# Stop Portal: Ctrl+C in the Portal terminal
```

## Switching Back to Full Docker

To run everything in Docker again:

```powershell
# Stop local dev
docker compose -f compose.local-dev.yaml down

# Start full stack
docker compose up -d
```
