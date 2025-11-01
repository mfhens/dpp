# Local Development Architecture

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Local Development Setup                      │
│                                                                   │
│  ┌───────────────┐        ┌───────────────┐                     │
│  │   Terminal 1  │        │   Terminal 2  │                     │
│  │               │        │               │                     │
│  │  Python API   │        │  Next.js      │                     │
│  │  (uvicorn)    │        │  Portal       │                     │
│  │               │        │               │                     │
│  │  Port: 8000   │        │  Port: 3000   │                     │
│  └───────┬───────┘        └───────┬───────┘                     │
│          │                        │                             │
│          │                        │                             │
│          ▼                        ▼                             │
│  ┌──────────────────────────────────────────┐                  │
│  │        localhost network                  │                  │
│  └──────────────┬───────────────────────────┘                  │
│                 │                                               │
│                 ▼                                               │
│  ┌─────────────────────────────────────────┐                   │
│  │         Docker Container                 │                   │
│  │                                          │                   │
│  │      PostgreSQL 15                       │                   │
│  │      Port: 5432                          │                   │
│  │      Database: dpp                       │                   │
│  │                                          │                   │
│  │      Volume: pgdata                      │                   │
│  │      Seeds: seed/postgres/*.sql          │                   │
│  │                                          │                   │
│  └─────────────────────────────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Full Stack vs Local Development

### Full Stack (All in Docker)
```
┌─────────────────────────────────────────────────────────┐
│                     Docker Network                       │
│                                                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │ Keycloak │  │   API    │  │  Portal  │  │   OPA   │ │
│  │  :8080   │  │  :8000   │  │  :3000   │  │  :8181  │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
│       │             │              │             │       │
│       └─────────────┴──────────────┴─────────────┘       │
│                          │                               │
│       ┌──────────────────┴─────────────────┐             │
│       │                                    │             │
│  ┌────▼──────┐  ┌──────────┐  ┌──────────▼───┐         │
│  │ PostgreSQL│  │  MinIO   │  │   ImmuDB     │         │
│  │   :5432   │  │  :9000   │  │   :3322      │         │
│  └───────────┘  └──────────┘  └──────────────┘         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Local Development (Minimal Docker)
```
┌────────────────────────────────────────────────────────────┐
│                      Your Machine                          │
│                                                             │
│  ┌──────────────────────┐    ┌──────────────────────┐     │
│  │   API (Local)        │    │   Portal (Local)     │     │
│  │   Python/FastAPI     │    │   Node.js/Next.js    │     │
│  │   localhost:8000     │    │   localhost:3000     │     │
│  │   Auto-reload ✓      │    │   Auto-reload ✓      │     │
│  │   IDE Debug ✓        │    │   IDE Debug ✓        │     │
│  └──────────┬───────────┘    └──────────┬───────────┘     │
│             │                           │                  │
│             └───────────┬───────────────┘                  │
│                         │                                  │
│                         ▼                                  │
│          ┌─────────────────────────┐                       │
│          │   Docker Container      │                       │
│          │   PostgreSQL only       │                       │
│          │   localhost:5432        │                       │
│          └─────────────────────────┘                       │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## Data Flow

### API Request Flow (Local Dev)
```
Browser/Client
    │
    │ HTTP Request
    ▼
http://localhost:3000 (Portal - Next.js)
    │
    │ API Call
    ▼
http://localhost:8000 (API - FastAPI)
    │
    │ SQL Query
    ▼
localhost:5432 (PostgreSQL - Docker)
    │
    │ Result
    ▼
Back to API → Portal → Browser
```

## File System Layout

```
dpp/
├── 📄 Scripts (PowerShell)
│   ├── setup-local-dev.ps1      ← Run this first
│   ├── start-local-dev.ps1      ← Daily: Start PostgreSQL
│   ├── stop-local-dev.ps1       ← Daily: Stop PostgreSQL
│   ├── setup-api.ps1            ← Setup API environment
│   └── setup-portal.ps1         ← Setup Portal environment
│
├── 🐳 Docker Configuration
│   ├── compose.local-dev.yaml   ← PostgreSQL only
│   └── compose.yaml             ← Full stack (original)
│
├── ⚙️ Environment Configuration
│   └── .env.local               ← Local dev variables
│
├── 🐍 API (Python)
│   ├── api/
│   │   ├── dpp_api/             ← Source code
│   │   ├── .env                 ← API config (generated)
│   │   ├── run.ps1              ← Run script (generated)
│   │   ├── .venv/               ← Virtual env (generated)
│   │   └── pyproject.toml       ← Dependencies
│
├── 🌐 Portal (TypeScript/Next.js)
│   ├── portal/
│   │   ├── app/                 ← Source code
│   │   ├── .env.local           ← Portal config (generated)
│   │   ├── run.ps1              ← Run script (generated)
│   │   ├── node_modules/        ← Dependencies (generated)
│   │   └── package.json         ← Dependencies
│
├── 🔐 Secrets (git-ignored)
│   └── secrets/
│       ├── database_url.txt
│       ├── jwt_secret.txt
│       └── ...
│
├── 🌱 Database Seeds
│   └── seed/postgres/
│       ├── 001_schema.sql
│       ├── 002_views.sql
│       └── 020_seed.sql
│
└── 📚 Documentation
    ├── LOCAL_DEV.md             ← Complete guide
    ├── QUICK_REFERENCE.md       ← Quick commands
    └── Readme.md                ← Project overview
```

## Network Ports

| Service | Port | Protocol | Access |
|---------|------|----------|--------|
| API | 8000 | HTTP | localhost:8000 |
| API Docs | 8000 | HTTP | localhost:8000/docs |
| Portal | 3000 | HTTP | localhost:3000 |
| PostgreSQL | 5432 | TCP | localhost:5432 |

## Development Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Cycle                         │
└─────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────┐
    │ 1. One-Time Setup                        │
    │    .\setup-local-dev.ps1                 │
    │    - Creates secrets                     │
    │    - Starts PostgreSQL                   │
    │    - Sets up API & Portal                │
    └──────────────┬───────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────────┐
    │ 2. Daily Start                           │
    │    .\start-local-dev.ps1                 │
    │    - Starts PostgreSQL                   │
    │    - Shows instructions                  │
    └──────────────┬───────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────────┐
    │ 3. Run Services (2 terminals)            │
    │    Terminal 1: cd api && .\run.ps1       │
    │    Terminal 2: cd portal && .\run.ps1    │
    └──────────────┬───────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────────┐
    │ 4. Code → Auto-Reload → Test             │
    │    - Edit code                           │
    │    - Services auto-reload                │
    │    - Test in browser                     │
    │    - Repeat                              │
    └──────────────┬───────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────────┐
    │ 5. Stop                                  │
    │    - Ctrl+C in terminals                 │
    │    - .\stop-local-dev.ps1                │
    └──────────────────────────────────────────┘
```

## Comparison: Docker vs Local

| Aspect | Full Docker | Local Dev |
|--------|-------------|-----------|
| **Startup Time** | ~60-90 seconds | ~5-10 seconds |
| **Code Reload** | Rebuild container | Instant |
| **Resource Usage** | High (7+ containers) | Low (1 container) |
| **Debugging** | Complex (attach to container) | Easy (native IDE) |
| **Logs** | Mixed in Docker logs | Clear console output |
| **Dependencies** | Docker only | Docker + Python + Node.js |
| **Best For** | Testing full system | Developing API/Portal |

## When to Use Each Mode

### Use Local Development When:
- ✅ Developing API or Portal features
- ✅ Debugging code
- ✅ Running tests frequently
- ✅ Making rapid changes
- ✅ Working on a laptop (resource-constrained)

### Use Full Docker When:
- ✅ Testing the complete system
- ✅ Testing authentication (Keycloak)
- ✅ Testing authorization (OPA)
- ✅ Testing object storage (MinIO)
- ✅ Testing audit trail (ImmuDB)
- ✅ Preparing for deployment

## Security Notes

🔒 **Secrets Management**
- Secrets stored in `secrets/` directory
- Never committed to git (.gitignored)
- Generated by `setup-secrets.ps1`
- Loaded from files by API and Portal

🔒 **Network Isolation**
- PostgreSQL only accessible from localhost
- No public exposure in local dev
- API and Portal run as your user (not root)

🔒 **Database Security**
- Credentials in secret files
- Connection only via localhost
- Data persisted in Docker volume
