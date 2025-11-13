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