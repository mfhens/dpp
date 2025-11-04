#!/usr/bin/env pwsh
<#
.SYNOPSIS
    View DPP API logs

.DESCRIPTION
    Utility script to view and monitor API logs with various filters

.PARAMETER Tail
    Show last N lines and follow (like tail -f)

.PARAMETER Lines
    Show last N lines only (no follow)

.PARAMETER Search
    Search for specific pattern in logs

.PARAMETER Level
    Filter by log level (INFO, DEBUG, WARNING, ERROR)

.PARAMETER Clear
    Clear the log file

.EXAMPLE
    .\view-logs.ps1
    Show all logs
    
.EXAMPLE
    .\view-logs.ps1 -Tail 50
    Show last 50 lines and follow
    
.EXAMPLE
    .\view-logs.ps1 -Search "Resolve DPP"
    Search for DPP resolution requests
    
.EXAMPLE
    .\view-logs.ps1 -Level ERROR
    Show only errors
#>

[CmdletBinding()]
param(
    [int]$Tail = 0,
    [int]$Lines = 0,
    [string]$Search = "",
    [ValidateSet("INFO", "DEBUG", "WARNING", "ERROR", "")]
    [string]$Level = "",
    [switch]$Clear
)

$ErrorActionPreference = "Stop"
$LogFile = "api/logs/dpp_api.log"

# Check if log file exists
if (-not (Test-Path $LogFile)) {
    Write-Host "❌ Log file not found: $LogFile" -ForegroundColor Red
    Write-Host "   Make sure the API has been started at least once" -ForegroundColor Yellow
    exit 1
}

# Clear log file
if ($Clear) {
    $confirm = Read-Host "Clear log file? (y/N)"
    if ($confirm -eq "y") {
        Clear-Content $LogFile
        Write-Host "✅ Log file cleared" -ForegroundColor Green
    }
    exit 0
}

Write-Host "📝 DPP API Logs" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "File: $LogFile" -ForegroundColor Gray
Write-Host ""

# Build filter command
$filterCmd = ""

if ($Level) {
    $filterCmd = "| Select-String -Pattern ' - $Level - '"
}

if ($Search) {
    if ($filterCmd) {
        $filterCmd += " | Select-String -Pattern '$Search'"
    } else {
        $filterCmd = "| Select-String -Pattern '$Search'"
    }
}

# Execute based on parameters
if ($Tail -gt 0) {
    Write-Host "📊 Following last $Tail lines (Ctrl+C to stop)..." -ForegroundColor Yellow
    Write-Host ""
    Invoke-Expression "Get-Content '$LogFile' -Tail $Tail -Wait $filterCmd"
} elseif ($Lines -gt 0) {
    Invoke-Expression "Get-Content '$LogFile' -Tail $Lines $filterCmd"
} elseif ($Search -or $Level) {
    Invoke-Expression "Get-Content '$LogFile' $filterCmd"
} else {
    Get-Content $LogFile
}
