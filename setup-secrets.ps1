# setup-secrets.ps1 - Generate secure secrets for Windows development
param(
    [switch]$Force,
    [string]$DataPath = "$PWD\data"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration
$SecretsDir = "$PWD\secrets"
$EnvFile = "$PWD\.env"

Write-Host "🔐 Setting up secure secrets management for Windows..." -ForegroundColor Green

# Create directories
if (-not (Test-Path $SecretsDir)) {
    New-Item -ItemType Directory -Path $SecretsDir -Force | Out-Null
}
if (-not (Test-Path $DataPath)) {
    New-Item -ItemType Directory -Path $DataPath -Force | Out-Null
}

# Create subdirectories for persistent data
@("postgres", "minio", "immudb", "keycloak") | ForEach-Object {
    $dir = Join-Path $DataPath $_
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Security: Set restrictive permissions on secrets directory
$acl = Get-Acl $SecretsDir
$acl.SetAccessRuleProtection($true, $false)
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.SetAccessRule($accessRule)
Set-Acl -Path $SecretsDir -AclObject $acl

# Generate secure random values
function New-SecurePassword {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($bytes)
    [Convert]::ToBase64String($bytes) -replace '[/+=]', ''
}

function New-SecureKey {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($bytes)
    ([System.BitConverter]::ToString($bytes) -replace '-', '').ToLower()
}

function New-SecureGuid {
    [System.Guid]::NewGuid().ToString()
}

# Create secret file
function Set-Secret {
    param(
        [string]$Name,
        [string]$Value
    )
    
    $filePath = Join-Path $SecretsDir "$Name.txt"
    
    if ((Test-Path $filePath) -and -not $Force) {
        Write-Host "⚠️  $Name already exists (use -Force to overwrite)" -ForegroundColor Yellow
        return
    }
    
    # Write secret to file (UTF8 without BOM)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($filePath, $Value, $utf8)
    
    # Set restrictive permissions
    $acl = Get-Acl $filePath
    $acl.SetAccessRuleProtection($true, $false)
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $env:USERNAME, "FullControl", "Allow"
    )
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $filePath -AclObject $acl
    
    Write-Host "✓ Generated $Name" -ForegroundColor Green
}

Write-Host "Generating database secrets..." -ForegroundColor Yellow
$postgresUser = "dpp_$((New-SecurePassword).Substring(0,8))"
$postgresPassword = New-SecurePassword
Set-Secret "postgres_user" $postgresUser
Set-Secret "postgres_password" $postgresPassword
Set-Secret "database_url" "postgresql+psycopg://$postgresUser`:$postgresPassword@postgres:5432/dpp"

Write-Host "Generating storage secrets..." -ForegroundColor Yellow
$minioUser = "minio_$((New-SecurePassword).Substring(0,8))"
$minioPassword = New-SecurePassword
Set-Secret "minio_root_user" $minioUser
Set-Secret "minio_root_password" $minioPassword

Write-Host "Generating ImmuDB secrets..." -ForegroundColor Yellow
Set-Secret "immudb_admin_password" (New-SecurePassword)

Write-Host "Generating Keycloak secrets..." -ForegroundColor Yellow
Set-Secret "keycloak_admin_user" "admin_$((New-SecurePassword).Substring(0,8))"
Set-Secret "keycloak_admin_password" (New-SecurePassword)

Write-Host "Generating application secrets..." -ForegroundColor Yellow
Set-Secret "oidc_client_secret" (New-SecurePassword)
Set-Secret "jwt_secret" (New-SecureKey)
Set-Secret "encryption_key" (New-SecureKey)
Set-Secret "nextauth_secret" (New-SecureKey)
Set-Secret "vault_token" (New-SecurePassword)

# Convert Windows path for Docker (handle drive letters and backslashes)
$dockerDataPath = $DataPath -replace '^([A-Z]):', '/$1' -replace '\\', '/'
$dockerDataPath = $dockerDataPath.ToLower()

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

$envContent | Out-File -FilePath $EnvFile -Encoding utf8 -NoNewline

# Create verification script
$verifyScript = @'
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

Write-Host "🔍 Verifying secrets configuration..." -ForegroundColor Cyan

$missingSecrets = @()
foreach ($secret in $RequiredSecrets) {
    $filePath = Join-Path $SecretsDir "$secret.txt"
    if (-not (Test-Path $filePath)) {
        $missingSecrets += $secret
    } elseif ((Get-Content $filePath -Raw).Length -eq 0) {
        Write-Host "⚠️  Warning: $secret file is empty" -ForegroundColor Yellow
    } else {
        Write-Host "✓ $secret configured" -ForegroundColor Green
    }
}

if ($missingSecrets.Count -gt 0) {
    Write-Host "❌ Missing secrets: $($missingSecrets -join ', ')" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ All secrets properly configured" -ForegroundColor Green
}
'@

$verifyScript | Out-File -FilePath "$PWD\verify-secrets.ps1" -Encoding utf8

# Create security directory and monitoring config
$securityDir = "$PWD\security"
if (-not (Test-Path $securityDir)) {
    New-Item -ItemType Directory -Path $securityDir -Force | Out-Null
}

# Update .gitignore
$gitignoreContent = @"
# Secrets and sensitive data
secrets/
.env
data/
*.key
*.pem
*.crt

# Docker
.docker/

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp

# Windows
Thumbs.db
Desktop.ini
"@

$gitignoreContent | Out-File -FilePath "$PWD\.gitignore" -Encoding utf8

Write-Host "🎉 Security setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review generated secrets in secrets\"
Write-Host "2. Customize .env file for your environment" 
Write-Host "3. Run: .\verify-secrets.ps1"
Write-Host "4. Start services: docker-compose up -d"
Write-Host ""
Write-Host "⚠️  IMPORTANT:" -ForegroundColor Red
Write-Host "- secrets/ directory is now in .gitignore"
Write-Host "- Use a proper secret manager for production"
Write-Host "- Change default ports for production deployment"