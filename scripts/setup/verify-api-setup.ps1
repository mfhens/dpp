#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify DPP API deployment setup and configuration
.DESCRIPTION
    This script validates the API deployment files, configuration, and dependencies
    for local, Docker, and Azure deployments.
.PARAMETER Mode
    Deployment mode to verify: local, docker, or azure
.EXAMPLE
    .\verify-api-setup.ps1 -Mode local
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("local", "docker", "azure", "all")]
    [string]$Mode = "all"
)

$ErrorActionPreference = "Continue"

# Colors
function Write-Check { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Fail { Write-Host "❌ $args" -ForegroundColor Red }
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Cyan }
function Write-Warn { Write-Host "⚠️  $args" -ForegroundColor Yellow }
function Write-Section { 
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "  $args" -ForegroundColor Blue
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""
}

$script:checksPassed = 0
$script:checksFailed = 0

function Test-Requirement {
    param(
        [string]$Name,
        [scriptblock]$Check,
        [string]$SuccessMessage,
        [string]$FailureMessage,
        [bool]$Required = $true
    )
    
    try {
        $result = & $Check
        if ($result) {
            Write-Check "$Name`: $SuccessMessage"
            $script:checksPassed++
            return $true
        } else {
            if ($Required) {
                Write-Fail "$Name`: $FailureMessage"
                $script:checksFailed++
            } else {
                Write-Warn "$Name`: $FailureMessage (optional)"
            }
            return $false
        }
    } catch {
        if ($Required) {
            Write-Fail "$Name`: $FailureMessage - $($_.Exception.Message)"
            $script:checksFailed++
        } else {
            Write-Warn "$Name`: $FailureMessage (optional)"
        }
        return $false
    }
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     DPP API Deployment Verification Script           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Determine project root
$ScriptDir = $PSScriptRoot
$ProjectRoot = $ScriptDir
$ApiDir = Join-Path $ProjectRoot "api"
$InfraDir = Join-Path $ProjectRoot "infra"

Write-Info "Project root: $ProjectRoot"
Write-Info "Mode: $Mode"
Write-Host ""

# ============================================================================
# Common Checks
# ============================================================================

if ($Mode -eq "all" -or $Mode -eq "local" -or $Mode -eq "docker" -or $Mode -eq "azure") {
    Write-Section "Common Requirements"
    
    Test-Requirement -Name "Project Structure" -Check {
        (Test-Path $ApiDir) -and (Test-Path (Join-Path $ApiDir "dpp_api"))
    } -SuccessMessage "API directory structure found" `
      -FailureMessage "API directory structure missing"
    
    Test-Requirement -Name "API Source" -Check {
        Test-Path (Join-Path $ApiDir "dpp_api\main.py")
    } -SuccessMessage "API main.py exists" `
      -FailureMessage "API main.py not found"
    
    Test-Requirement -Name "Configuration" -Check {
        Test-Path (Join-Path $ApiDir "dpp_api\config.py")
    } -SuccessMessage "Config file exists" `
      -FailureMessage "Config file not found"
    
    Test-Requirement -Name "Dependencies" -Check {
        Test-Path (Join-Path $ApiDir "pyproject.toml")
    } -SuccessMessage "pyproject.toml exists" `
      -FailureMessage "pyproject.toml not found"
    
    Test-Requirement -Name "Schemas" -Check {
        Test-Path (Join-Path $ProjectRoot "schemas\core\1-0-0.schema.json")
    } -SuccessMessage "Core schema found" `
      -FailureMessage "Core schema missing"
    
    Test-Requirement -Name "Documentation" -Check {
        (Test-Path (Join-Path $ApiDir "README.md")) -and 
        (Test-Path (Join-Path $ApiDir "QUICKSTART.md"))
    } -SuccessMessage "API documentation exists" `
      -FailureMessage "API documentation missing" -Required $false
}

# ============================================================================
# Local Development Checks
# ============================================================================

if ($Mode -eq "all" -or $Mode -eq "local") {
    Write-Section "Local Development Setup"
    
    Test-Requirement -Name "Python" -Check {
        $null -ne (Get-Command python -ErrorAction SilentlyContinue)
    } -SuccessMessage "Python is installed" `
      -FailureMessage "Python not found"
    
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonVersion = python --version 2>&1
        Write-Info "  Version: $pythonVersion"
    }
    
    Test-Requirement -Name "uv" -Check {
        $null -ne (Get-Command uv -ErrorAction SilentlyContinue)
    } -SuccessMessage "uv package manager is installed" `
      -FailureMessage "uv not found - install with: pip install uv"
    
    Test-Requirement -Name "Local Run Script" -Check {
        Test-Path (Join-Path $ProjectRoot "run-api-local.ps1")
    } -SuccessMessage "Local run script exists" `
      -FailureMessage "run-api-local.ps1 not found"
    
    Test-Requirement -Name "Drop Folder" -Check {
        $dropPath = Join-Path $ApiDir "drop"
        if (-not (Test-Path $dropPath)) {
            New-Item -ItemType Directory -Path $dropPath -Force | Out-Null
        }
        Test-Path $dropPath
    } -SuccessMessage "Drop folder ready" `
      -FailureMessage "Could not create drop folder" -Required $false
    
    Test-Requirement -Name "Logs Folder" -Check {
        $logsPath = Join-Path $ApiDir "logs"
        if (-not (Test-Path $logsPath)) {
            New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
        }
        Test-Path $logsPath
    } -SuccessMessage "Logs folder ready" `
      -FailureMessage "Could not create logs folder" -Required $false
}

# ============================================================================
# Docker Checks
# ============================================================================

if ($Mode -eq "all" -or $Mode -eq "docker") {
    Write-Section "Docker Deployment Setup"
    
    Test-Requirement -Name "Docker" -Check {
        $null -ne (Get-Command docker -ErrorAction SilentlyContinue)
    } -SuccessMessage "Docker is installed" `
      -FailureMessage "Docker not found"
    
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        try {
            $dockerVersion = docker version --format '{{.Server.Version}}' 2>&1
            Write-Info "  Docker version: $dockerVersion"
        } catch {
            Write-Warn "  Docker daemon may not be running"
        }
    }
    
    Test-Requirement -Name "Docker Compose" -Check {
        Test-Path (Join-Path $ProjectRoot "compose.yaml")
    } -SuccessMessage "compose.yaml exists" `
      -FailureMessage "compose.yaml not found"
    
    Test-Requirement -Name "Dockerfile" -Check {
        Test-Path (Join-Path $ApiDir "Dockerfile")
    } -SuccessMessage "API Dockerfile exists" `
      -FailureMessage "Dockerfile not found"
    
    Test-Requirement -Name "Secrets Setup" -Check {
        Test-Path (Join-Path $ProjectRoot "setup-secrets.ps1")
    } -SuccessMessage "Secrets setup script exists" `
      -FailureMessage "setup-secrets.ps1 not found"
    
    Test-Requirement -Name "Secrets Directory" -Check {
        Test-Path (Join-Path $ProjectRoot "secrets")
    } -SuccessMessage "Secrets directory exists" `
      -FailureMessage "Run ./setup-secrets.ps1 to create secrets" -Required $false
}

# ============================================================================
# Azure Checks
# ============================================================================

if ($Mode -eq "all" -or $Mode -eq "azure") {
    Write-Section "Azure Deployment Setup"
    
    Test-Requirement -Name "Azure CLI" -Check {
        $null -ne (Get-Command az -ErrorAction SilentlyContinue)
    } -SuccessMessage "Azure CLI is installed" `
      -FailureMessage "Azure CLI not found - install from https://aka.ms/azure-cli"
    
    if (Get-Command az -ErrorAction SilentlyContinue) {
        Test-Requirement -Name "Azure Login" -Check {
            $account = az account show 2>$null | ConvertFrom-Json
            if ($account) {
                Write-Info "  Subscription: $($account.name)"
                Write-Info "  User: $($account.user.name)"
                return $true
            }
            return $false
        } -SuccessMessage "Logged in to Azure" `
          -FailureMessage "Not logged in - run: az login" -Required $false
    }
    
    Test-Requirement -Name "Infrastructure Directory" -Check {
        Test-Path $InfraDir
    } -SuccessMessage "Infrastructure directory exists" `
      -FailureMessage "infra/ directory not found"
    
    Test-Requirement -Name "Bicep Template" -Check {
        Test-Path (Join-Path $InfraDir "api.bicep")
    } -SuccessMessage "API Bicep template exists" `
      -FailureMessage "api.bicep not found"
    
    Test-Requirement -Name "Parameters File" -Check {
        Test-Path (Join-Path $InfraDir "api.parameters.json")
    } -SuccessMessage "Parameters file exists" `
      -FailureMessage "api.parameters.json not found"
    
    Test-Requirement -Name "Deployment Script" -Check {
        Test-Path (Join-Path $InfraDir "deploy-api.ps1")
    } -SuccessMessage "Deployment script exists" `
      -FailureMessage "deploy-api.ps1 not found"
    
    Test-Requirement -Name "Startup Script" -Check {
        Test-Path (Join-Path $ApiDir "startup.sh")
    } -SuccessMessage "Azure startup script exists" `
      -FailureMessage "startup.sh not found"
}

# ============================================================================
# Documentation Checks
# ============================================================================

if ($Mode -eq "all") {
    Write-Section "Documentation"
    
    Test-Requirement -Name "Deployment Summary" -Check {
        Test-Path (Join-Path $ProjectRoot "docs\API_DEPLOYMENT_SUMMARY.md")
    } -SuccessMessage "Deployment summary exists" `
      -FailureMessage "API_DEPLOYMENT_SUMMARY.md not found" -Required $false
    
    Test-Requirement -Name "Azure Checklist" -Check {
        Test-Path (Join-Path $ProjectRoot "docs\AZURE_API_CHECKLIST.md")
    } -SuccessMessage "Azure checklist exists" `
      -FailureMessage "AZURE_API_CHECKLIST.md not found" -Required $false
    
    Test-Requirement -Name "Dual Deployment Guide" -Check {
        Test-Path (Join-Path $ProjectRoot "docs\API_DUAL_DEPLOYMENT.md")
    } -SuccessMessage "Dual deployment guide exists" `
      -FailureMessage "API_DUAL_DEPLOYMENT.md not found" -Required $false
}

# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Section "Verification Summary"

$total = $script:checksPassed + $script:checksFailed
$percentage = if ($total -gt 0) { [math]::Round(($script:checksPassed / $total) * 100, 1) } else { 0 }

Write-Host "Total checks: $total" -ForegroundColor White
Write-Host "Passed: $script:checksPassed" -ForegroundColor Green
Write-Host "Failed: $script:checksFailed" -ForegroundColor $(if ($script:checksFailed -eq 0) { "Green" } else { "Red" })
Write-Host "Success rate: $percentage%" -ForegroundColor $(if ($percentage -ge 80) { "Green" } elseif ($percentage -ge 60) { "Yellow" } else { "Red" })
Write-Host ""

if ($script:checksFailed -eq 0) {
    Write-Check "All checks passed! Your deployment setup is ready."
    Write-Host ""
    Write-Info "Next steps:"
    if ($Mode -eq "local" -or $Mode -eq "all") {
        Write-Host "  • Local: .\run-api-local.ps1"
    }
    if ($Mode -eq "docker" -or $Mode -eq "all") {
        Write-Host "  • Docker: docker compose up -d api"
    }
    if ($Mode -eq "azure" -or $Mode -eq "all") {
        Write-Host "  • Azure: cd infra; .\deploy-api.ps1 -ResourceGroupName 'dpp-rg'"
    }
    Write-Host ""
    exit 0
} else {
    Write-Fail "Some checks failed. Please address the issues above."
    Write-Host ""
    Write-Info "For help, see:"
    Write-Host "  • api/README.md - Comprehensive guide"
    Write-Host "  • api/QUICKSTART.md - Quick reference"
    Write-Host "  • docs/API_DEPLOYMENT_SUMMARY.md - Deployment overview"
    Write-Host ""
    exit 1
}
