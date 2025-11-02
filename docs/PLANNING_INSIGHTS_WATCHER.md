# Planning Insights File Watcher

Automated system for processing planning insights CSV files and updating DPPs.

## Overview

The file watcher monitors the `api/drop` folder for new CSV files containing planning insights data. When a new CSV file is detected:

1. ✅ **Debounces** - Waits 2 seconds to ensure file is completely written
2. ✅ **Validates** - Checks if file has already been processed (by hash)
3. ✅ **Processes** - Reads CSV and updates matching DPPs with planning insights
4. ✅ **Archives** - Moves processed file to timestamped archive folder
5. ✅ **Manifests** - Creates JSON manifest with processing statistics and results

## Quick Start

### Option 1: PowerShell Script (Recommended)

```powershell
# From project root
.\watch-planning-insights.ps1
```

### Option 2: Python Module

```powershell
# From api directory
cd api
python -m dpp_api.planning_insights_watcher
```

## CSV File Format

The watcher expects CSV files with semicolon delimiter:

```csv
LOCFR;LOCID;PRDID;ADJUSTEDTRANSPORT;TRANSPORT;SC1STOREDPREVTRANSPFOOTPRFINAL;SC1STOREDTRANSPFOOTPRFINAL
GE01;2001;LEGO-DUCK;300;250;4;5
PL01;2001;LEGO-DUCK;200;250;6;5
```

### Columns

- `LOCFR` - Location From (e.g., GE01, PL01)
- `LOCID` - Location ID (facility ID)
- `PRDID` - Product ID/Model (e.g., LEGO-DUCK)
- `ADJUSTEDTRANSPORT` - Optimized transport cost
- `TRANSPORT` - Standard transport cost
- `SC1STOREDPREVTRANSPFOOTPRFINAL` - Previous carbon footprint
- `SC1STOREDTRANSPFOOTPRFINAL` - Current carbon footprint

## How It Works

### 1. Drop CSV File

Place your CSV file in `api/drop/`:

```powershell
Copy-Item planning_data.csv api/drop/
```

### 2. Automatic Processing

The watcher will:
- Detect the new file
- Wait 2 seconds (debounce)
- Process the CSV
- Update DPPs via database

### 3. Check Results

Processed files are archived to:
```
api/drop/processed/YYYYMMDD_HHMMSS_filename/
  ├── planning_data.csv         # Original file
  └── manifest.json              # Processing results
```

### Manifest Example

```json
{
  "manifest_version": "1.0",
  "processing_result": {
    "file": "planning_data.csv",
    "file_hash": "abc123...",
    "processed_at": "2025-11-02T15:30:00Z",
    "completed_at": "2025-11-02T15:30:05Z",
    "duration_seconds": 5.2,
    "success": true,
    "statistics": {
      "records_read": 4,
      "products_found": 1,
      "dpps_updated": 1,
      "dpps_not_found": 0
    },
    "errors": []
  }
}
```

## Features

### ✅ Duplicate Detection

Files are hashed (SHA256) and checked against all previous manifests. If a file has already been processed (same hash), it's moved to a `duplicate` folder without reprocessing.

### ✅ Error Handling

- Invalid CSV format → Error logged in manifest
- Product not found → Logged as warning, continues with other products
- DPP update failure → Error logged, processing continues

### ✅ Automatic Archival

Original CSV files are automatically archived after processing, so they won't be picked up again.

### ✅ Detailed Statistics

Every processing run creates a manifest with:
- File hash (for duplicate detection)
- Processing timestamps
- Success/failure status
- Records processed
- DPPs updated
- Errors encountered

## Configuration

### Custom Drop Folder

```powershell
.\watch-planning-insights.ps1 -DropFolder "C:\data\planning"
```

Or:

```powershell
python -m dpp_api.planning_insights_watcher "C:\data\planning"
```

### Custom Debounce Time

```powershell
.\watch-planning-insights.ps1 -Debounce 5.0  # 5 seconds
```

Or:

```powershell
python -m dpp_api.planning_insights_watcher "api/drop" 5.0
```

## Manual Processing

To process a CSV file without the watcher:

```powershell
cd api
python -m dpp_api.update_planning_insights
```

For dry-run (preview without updating):

```powershell
python -m dpp_api.update_planning_insights --dry-run
```

## Monitoring

### View Real-time Processing

The watcher outputs detailed logs:

```
🔔 New file detected: planning_2025.csv

============================================================
🚀 Processing: planning_2025.csv
============================================================

📊 Processing planning_2025.csv...
   Hash: abc123...
   Records: 4
   Products: 1

  Processing LEGO-DUCK...
    Found: did:web:dpp.brickquack.com:product:lego-duck:item-SN-2025-LD-001234
    ✅ Updated

============================================================
📦 Archiving...
============================================================
📁 Archived: C:\...\20251102_153000_planning_2025\planning_2025.csv
📄 Manifest: C:\...\20251102_153000_planning_2025\manifest.json
🗑️  Deleted: planning_2025.csv

============================================================
✅ Processing Complete
============================================================
Duration: 5.2s
Success: True
Updated: 1 DPPs
============================================================
```

### Check Archive

View processed files:

```powershell
Get-ChildItem api/drop/processed -Recurse
```

View manifest:

```powershell
Get-Content api/drop/processed/*/manifest.json | ConvertFrom-Json
```

## Troubleshooting

### Watcher Not Starting

1. Check Python virtual environment:
   ```powershell
   Test-Path api/.venv/Scripts/python.exe
   ```

2. Install dependencies:
   ```powershell
   cd api
   pip install -e .
   pip install watchdog
   ```

### Files Not Being Processed

1. Check file extension is `.csv` (case-insensitive)
2. Check file is in correct folder (`api/drop`, not `api/drop/processed`)
3. Check terminal for error messages

### DPP Not Found

The product ID in the CSV (`PRDID` column) must match either:
- The `product_id` field in the DPP header, OR
- The `product.model` field in the DPP payload

Example: `LEGO-DUCK` matches `product.model: "LEGO-DUCK"` in the payload.

## Integration

### Running as Background Service

**Windows (Task Scheduler):**
1. Create scheduled task
2. Trigger: At startup
3. Action: Run `watch-planning-insights.ps1`
4. Run whether user is logged on or not

**Linux/Mac (systemd):**
```ini
[Unit]
Description=DPP Planning Insights Watcher
After=network.target

[Service]
Type=simple
User=dpp
WorkingDirectory=/path/to/dpp
ExecStart=/path/to/dpp/api/.venv/bin/python -m dpp_api.planning_insights_watcher
Restart=always

[Install]
WantedBy=multi-user.target
```

### API Integration

The watcher can be imported and used programmatically:

```python
from dpp_api.planning_insights_watcher import watch_folder
from pathlib import Path

# Start watching
watch_folder(Path("./drop"), debounce_seconds=2.0)
```

## Related Files

- `api/dpp_api/planning_insights_watcher.py` - Main watcher implementation
- `api/dpp_api/update_planning_insights.py` - CSV processing logic
- `watch-planning-insights.ps1` - PowerShell launcher script
- `api/drop/` - Drop folder (monitored)
- `api/drop/processed/` - Archive folder (with manifests)

## Example Workflow

1. **Export planning data** from ERP/planning system as CSV
2. **Drop file** into `api/drop/` folder
3. **Watcher automatically**:
   - Detects file
   - Processes CSV
   - Updates DPPs in database
   - Archives file with manifest
4. **View updated DPPs** in portal at `http://localhost:3000/dpp/{id}`
5. **Check processing results** in manifest

## Notes

- Files are processed sequentially (not in parallel)
- The watcher uses file system events (near real-time)
- Duplicate detection prevents reprocessing same data
- All processing is atomic (database transactions)
- Original files are preserved in archive
