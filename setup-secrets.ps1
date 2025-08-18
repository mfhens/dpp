# setup-secrets.ps1 - Generate secure secrets for Windows development
param(
    [switch]$Force,
    [string]$DataPath = "$PWD\data"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration
$SecretsDir = "$PWD\secrets"
$EnvFile   = "$PWD\.env"

Write-Host "Setting up secure secrets management for Windows..." -ForegroundColor Green

# Create directories
if (-not (Test-Path $SecretsDir)) {
    New-Item -ItemType Directory -Path $SecretsDir -Force | Out-Null
}
if (-not (Test-Path $DataPath)) {
    New-Item -ItemType Directory -Path $DataPath -Force | Out-Null
}

# Create subdirectories for persistent data
$subdirs = @("postgres", "minio", "immudb", "keycloak")
foreach ($dir in $subdirs) {
    $fullPath = Join-Path $DataPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
}

# Generate secure random values
function New-SecurePassword {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($bytes)
    $password = [Convert]::ToBase64String($bytes)
    $rng.Dispose()
    return ($password -replace '[/+=]', '')
}

function New-SecureKey {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($bytes)
    $key = ([System.BitConverter]::ToString($bytes) -replace '-', '').ToLower()
    $rng.Dispose()
    return $key
}

# Create secret file
function Set-Secret {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Value
    )

    $filePath = Join-Path $SecretsDir "$Name.txt"

    if ((Test-Path $filePath) -and -not $Force) {
        Write-Host "$Name already exists (use -Force to overwrite)" -ForegroundColor Yellow
        return
    }

    # Write secret to file (UTF8 without BOM)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($filePath, $Value, $utf8)

    Write-Host "Generated $Name" -ForegroundColor Green
}

Write-Host "Generating database secrets..." -ForegroundColor Yellow
$postgresUser = "dpp_" + (New-SecurePassword).Substring(0,8)
$postgresPassword = New-SecurePassword
Set-Secret "postgres_user" $postgresUser
Set-Secret "postgres_password" $postgresPassword
Set-Secret "database_url" "postgresql+psycopg://$postgresUser`:$postgresPassword@postgres:5432/dpp"

Write-Host "Generating storage secrets..." -ForegroundColor Yellow
$minioUser = "minio_" + (New-SecurePassword).Substring(0,8)
$minioPassword = New-SecurePassword
Set-Secret "minio_root_user" $minioUser
Set-Secret "minio_root_password" $minioPassword

Write-Host "Generating ImmuDB secrets..." -ForegroundColor Yellow
Set-Secret "immudb_admin_password" (New-SecurePassword)

Write-Host "Generating Keycloak secrets..." -ForegroundColor Yellow
Set-Secret "keycloak_admin_user" ("admin_" + (New-SecurePassword).Substring(0,8))
Set-Secret "keycloak_admin_password" (New-SecurePassword)

Write-Host "Generating application secrets..." -ForegroundColor Yellow
Set-Secret "oidc_client_secret" (New-SecurePassword)
Set-Secret "jwt_secret" (New-SecureKey)
Set-Secret "encryption_key" (New-SecureKey)
Set-Secret "nextauth_secret" (New-SecureKey)
Set-Secret "vault_token" (New-SecurePassword)

# Convert Windows path for Docker
$dockerDataPath = $DataPath -replace '\\', '/'
if ($dockerDataPath -match '^([A-Z]):') {
    $driveLetter = $matches[1].ToLower()
    $dockerDataPath = $dockerDataPath -replace '^[A-Z]:', "/$driveLetter"
}

# Create environment file
$envContent = @"
# Platform Configuration - Windows Development
DATA_PATH=$dockerDataPath
POSTGRES_DB=dpp
COMPOSE_PROJECT_NAME=dpp-platform

# Port Configuration (change for production)
POSTGRES_PORT=5432
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001
IMMUDB_PORT=3322
KEYCLOAK_PORT=8080
OPA_PORT=8181
API_PORT=8000
PORTAL_PORT=3000

# Public URLs (change for production)
PUBLIC_KEYCLOAK_URL=http://localhost:8080/realms/dpp
PUBLIC_PORTAL_URL=http://localhost:3000

# Security Configuration
SECRETS_ROTATION_INTERVAL=24h
VAULT_ADDR=http://vault:8200

# Monitoring
ENABLE_MONITORING=false
LOG_LEVEL=INFO

# Windows-specific settings
COMPOSE_CONVERT_WINDOWS_PATHS=1
"@

[System.IO.File]::WriteAllText($EnvFile, $envContent, [System.Text.Encoding]::UTF8)

# Create verification script
$verifyScriptContent = @'
# verify-secrets.ps1 - Verify all secrets are properly configured
$SecretsDir = "$PWD\secrets"
$RequiredSecrets = @(
    "postgres_user",
    "postgres_password",
    "minio_root_user",
    "minio_root_password",
    "immudb_admin_password",
    "keycloak_admin_user",
    "keycloak_admin_password",
    "database_url",
    "oidc_client_secret",
    "jwt_secret",
    "encryption_key",
    "nextauth_secret",
    "vault_token"
)

Write-Host "Verifying secrets configuration..." -ForegroundColor Cyan

$missingSecrets = @()
foreach ($secret in $RequiredSecrets) {
    $filePath = Join-Path $SecretsDir "$secret.txt"
    if (-not (Test-Path $filePath)) {
        $missingSecrets += $secret
    } elseif ((Get-Content $filePath -Raw -ErrorAction SilentlyContinue).Length -eq 0) {
        Write-Host "Warning: $secret file is empty" -ForegroundColor Yellow
    } else {
        Write-Host "$secret configured" -ForegroundColor Green
    }
}

if ($missingSecrets.Count -gt 0) {
    Write-Host "Missing secrets: $($missingSecrets -join ', ')" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All secrets properly configured" -ForegroundColor Green
}
'@

[System.IO.File]::WriteAllText("$PWD\verify-secrets.ps1", $verifyScriptContent, [System.Text.Encoding]::UTF8)

# Create security directory
$securityDir = "$PWD\security"
if (-not (Test-Path $securityDir)) {
    New-Item -ItemType Directory -Path $securityDir -Force | Out-Null
}

Write-Host ""
Write-Host "Security setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review generated secrets in secrets\ directory"
Write-Host "2. Run: .\verify-secrets.ps1"
Write-Host "3. Start services: docker-compose up -d"
Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Red
Write-Host "- secrets\ directory is now in .gitignore"
Write-Host "- Use a proper secret manager for production"
Write-Host "- Change default ports for production deployment"
