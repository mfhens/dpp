# File Watcher Integration

## Overview

The Planning Insights file watcher is now **integrated into the FastAPI application** and starts automatically when you run the API server.

## Features

✅ **Automatic Startup** - Watcher starts when API starts  
✅ **Background Operation** - Runs in separate thread, doesn't block API  
✅ **Structured Logging** - Uses Python logging module with configurable levels  
✅ **Graceful Shutdown** - Stops cleanly when API stops  
✅ **Environment Configuration** - Control via environment variables  

## Quick Start

### Start API (with watcher enabled)

```powershell
cd api
uvicorn dpp_api.main:app --reload
```

The file watcher will start automatically and monitor `api/drop/` folder.

### Disable File Watcher

Set environment variable:

```powershell
$env:ENABLE_FILE_WATCHER = "false"
uvicorn dpp_api.main:app --reload
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_FILE_WATCHER` | `true` | Enable/disable file watcher |
| `DROP_FOLDER` | `api/drop` | Path to folder to monitor |
| `WATCHER_DEBOUNCE` | `2.0` | Seconds to wait after file creation |
| `LOG_LEVEL` | `INFO` | Logging level (DEBUG, INFO, WARNING, ERROR) |
| `LOG_TO_FILE` | `false` | Enable file logging |
| `LOG_FILE` | `logs/dpp_api.log` | Log file path (relative to api directory) |

### Example Configuration

```powershell
# Custom drop folder
$env:DROP_FOLDER = "C:\data\planning_insights"

# Longer debounce for slower file systems
$env:WATCHER_DEBOUNCE = "5.0"

# Enable debug logging to file
$env:LOG_LEVEL = "DEBUG"
$env:LOG_TO_FILE = "true"

# Start API
uvicorn dpp_api.main:app --reload
```

### Using run-local.ps1

When running via `run-local.ps1`, the following is configured automatically:

- ✅ **LOG_LEVEL**: Set to `DEBUG` by default
- ✅ **LOG_TO_FILE**: Enabled automatically
- ✅ **LOG_FILE**: Set to `api/logs/dpp_api.log`
- ✅ **Log rotation**: 10MB max file size, 5 backup files

```powershell
.\run-local.ps1 -Seed
```

This will:
1. Start API with DEBUG logging
2. Log to both console and `api/logs/dpp_api.log`
3. Enable file watcher automatically
4. Seed database with sample data

## Logging

### Log Levels

The watcher now uses Python's `logging` module with these levels:

- **INFO** - Normal operations (file detected, processed, archived)
- **WARNING** - Non-critical issues (DPP not found, duplicate file)
- **ERROR** - Errors (processing failed, file read error)
- **DEBUG** - Detailed information (file hashes, found DPP IDs)

### Enable Debug Logging

**When using run-local.ps1** (Recommended for development):
```powershell
.\run-local.ps1 -Seed
```
Debug logging and file logging are enabled automatically!

**When running manually:**
```powershell
$env:LOG_LEVEL = "DEBUG"
$env:LOG_TO_FILE = "true"
uvicorn dpp_api.main:app --reload
```

### View Log Files

**Tail the log file** (PowerShell):
```powershell
Get-Content api/logs/dpp_api.log -Wait -Tail 50
```

**View recent entries**:
```powershell
Get-Content api/logs/dpp_api.log -Tail 100
```

**Search logs**:
```powershell
Select-String -Path api/logs/dpp_api.log -Pattern "error" -Context 2
```

### Log Format

**Console and File Output:**
```
2025-11-04 10:30:45,123 - dpp_api.planning_insights_watcher - INFO - 🔔 New file detected: planning.csv
2025-11-04 10:30:47,234 - dpp_api.planning_insights_watcher - INFO - 📊 Processing planning.csv...
2025-11-04 10:30:47,345 - dpp_api.planning_insights_watcher - INFO -    Records: 4
2025-11-04 10:30:47,456 - dpp_api.planning_insights_watcher - INFO -    Products: 1
2025-11-04 10:30:47,567 - dpp_api.planning_insights_watcher - INFO -   Processing LEGO-DUCK...
2025-11-04 10:30:47,678 - dpp_api.update_planning_insights - INFO - ✅ Updated did:web:... -> v2
2025-11-04 10:30:47,789 - dpp_api.planning_insights_watcher - INFO - 📁 Archived: C:\...\processed\...
```

### Log Rotation

File logs are automatically rotated:
- **Max file size**: 10MB
- **Backup count**: 5 files kept
- **Files**: `dpp_api.log`, `dpp_api.log.1`, `dpp_api.log.2`, etc.

## Behavior

### On API Startup

1. Database initialized
2. File watcher checks `ENABLE_FILE_WATCHER` env var
3. If enabled:
   - Creates drop folder if needed
   - Starts watchdog observer
   - Launches background thread for processing
   - Logs startup confirmation
4. API is ready to handle requests

### During Operation

- Watcher monitors drop folder in background
- When CSV file appears:
  1. Waits debounce period (default 2s)
  2. Checks if already processed (hash comparison)
  3. Processes CSV and updates DPPs
  4. Archives file with manifest
  5. Logs results
- API continues serving requests normally

### On API Shutdown

1. Shutdown signal received (Ctrl+C or SIGTERM)
2. Watcher observer stops
3. Background thread terminates
4. API shuts down gracefully

## Standalone Usage (Optional)

You can still run the watcher as a standalone process if needed:

```powershell
# Option 1: PowerShell script
.\watch-planning-insights.ps1

# Option 2: Python module
cd api
python -m dpp_api.planning_insights_watcher
```

## Troubleshooting

### Watcher Not Starting

Check logs on API startup:

```
INFO - 🚀 Starting Planning Insights File Watcher
INFO -    Drop folder: C:\...\api\drop
INFO -    Debounce: 2.0s
INFO - ✅ File watcher started successfully
```

If you see errors, check:
- `watchdog` package installed: `pip install watchdog`
- Drop folder permissions
- Environment variables

### No Files Being Processed

1. Check watcher is enabled:
   ```
   INFO - ✅ File watcher started successfully
   ```
   
2. Check drop folder location:
   ```
   INFO -    Drop folder: <path>
   ```

3. Verify file is `.csv` extension

4. Check logs for file detection:
   ```
   INFO - 🔔 New file detected: filename.csv
   ```

### High CPU Usage

Reduce polling frequency by increasing debounce:

```powershell
$env:WATCHER_DEBOUNCE = "5.0"
```

## Architecture

```
FastAPI App (main.py)
├── Startup Event
│   ├── Initialize Database
│   └── Start File Watcher (if enabled)
│       ├── Create Observer
│       └── Launch Background Thread
│           └── Monitor & Process Files
├── API Endpoints
│   └── Normal request handling
└── Shutdown Event
    └── Stop File Watcher
        ├── Stop Observer
        └── Join Thread
```

## Benefits of Integration

### Before (Standalone)
- ❌ Required separate terminal/process
- ❌ Manual startup required
- ❌ Separate logging configuration
- ❌ No coordination with API lifecycle

### After (Integrated)
- ✅ Single command starts everything
- ✅ Automatic startup with API
- ✅ Unified logging system
- ✅ Coordinated lifecycle management
- ✅ Environment-based configuration

## Migration Notes

If you were previously using the standalone watcher:

1. **Stop** any running standalone watcher processes
2. **Start** the API normally - watcher auto-starts
3. **Optional**: Keep `watch-planning-insights.ps1` for standalone use cases

No code changes required - existing CSV processing logic unchanged.
