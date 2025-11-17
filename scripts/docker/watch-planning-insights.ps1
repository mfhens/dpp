#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start the Planning Insights file watcher

.DESCRIPTION
    Monitors the drop folder for new CSV files containing planning insights,
    processes them automatically, and archives them with a manifest.

.PARAMETER DropFolder
    Path to folder to watch (default: api/drop)

.PARAMETER Debounce
    Seconds to wait after file creation before processing (default: 2.0)

.EXAMPLE
    .\watch-planning-insights.ps1
    
.EXAMPLE
    .\watch-planning-insights.ps1 -DropFolder "C:\data\planning" -Debounce 5
#>

[CmdletBinding()]
param(
    [string]$DropFolder = "api/drop",
    [double]$Debounce = 2.0
)

$ErrorActionPreference = "Stop"

Write-Host "👁️  Planning Insights File Watcher" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check if running from project root
if (-not (Test-Path "api/dpp_api")) {
    Write-Error "Please run this script from the project root directory"
    exit 1
}

# Set environment for development mode
$env:ENVIRONMENT = "development"
$env:DATABASE_URL = "sqlite+pysqlite:///./api/dpp.db"

# Check for Python
$pythonPath = "api/.venv/Scripts/python.exe"
if (-not (Test-Path $pythonPath)) {
    Write-Error "Python virtual environment not found at: $pythonPath"
    Write-Host "Please run setup first from the api directory" -ForegroundColor Yellow
    exit 1
}

# Start watcher
Write-Host "Starting watcher..." -ForegroundColor Green
Write-Host "  Folder: $DropFolder" -ForegroundColor Gray
Write-Host "  Debounce: $Debounce seconds" -ForegroundColor Gray
Write-Host ""

try {
    & $pythonPath -m dpp_api.planning_insights_watcher $DropFolder $Debounce
} catch {
    Write-Error "Failed to start watcher: $_"
    exit 1
}
