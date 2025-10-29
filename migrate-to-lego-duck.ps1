# Switch Database Seed to Lego Duck Examples
# This script applies the Lego Duck sample DPP data to your database

Write-Host "`n🔄 Database Seed Migration - Lego Duck Examples" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# Check if docker-compose is available
if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: docker-compose not found" -ForegroundColor Red
    Write-Host "Please install Docker Desktop for Windows" -ForegroundColor Yellow
    exit 1
}

# Check if we're in the correct directory
if (!(Test-Path "compose.yaml")) {
    Write-Host "❌ Error: compose.yaml not found" -ForegroundColor Red
    Write-Host "Please run this script from the dpp project root directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n📋 Pre-flight Checks:" -ForegroundColor Yellow
Write-Host "  ✅ Docker Compose found" -ForegroundColor Green
Write-Host "  ✅ Project directory correct" -ForegroundColor Green

# Check if seed files exist
$seedFile = "seed\postgres\lego-duck-sample-dpps.ndjson"
$seedScript = "seed\postgres\020_seed.sql"

if (!(Test-Path $seedFile)) {
    Write-Host "  ❌ $seedFile not found" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $seedScript)) {
    Write-Host "  ❌ $seedScript not found" -ForegroundColor Red
    exit 1
}

Write-Host "  ✅ Seed files found" -ForegroundColor Green

# Count records in seed file
$recordCount = (Get-Content $seedFile | Where-Object { $_.Trim() -ne "" }).Count
Write-Host "  ✅ $recordCount DPP records ready to load" -ForegroundColor Green

# Warn about data loss
Write-Host "`n⚠️  WARNING: This will DELETE all existing database data!" -ForegroundColor Yellow
Write-Host "   The '-v' flag removes all volumes and data." -ForegroundColor Yellow
$confirm = Read-Host "`nDo you want to continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "`n❌ Operation cancelled by user" -ForegroundColor Red
    exit 0
}

Write-Host "`n🛑 Stopping services and removing volumes..." -ForegroundColor Cyan
docker-compose down -v

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to stop services" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Services stopped and volumes removed" -ForegroundColor Green

Write-Host "`n🚀 Starting services..." -ForegroundColor Cyan
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start services" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Services starting..." -ForegroundColor Green

Write-Host "`n⏳ Waiting for database initialization..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Wait for postgres to be healthy
$maxAttempts = 30
$attempt = 0
$healthy = $false

while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "   Checking database health (attempt $attempt/$maxAttempts)..." -ForegroundColor Gray
    
    $healthStatus = docker-compose ps postgres --format json | ConvertFrom-Json
    if ($healthStatus.Health -eq "healthy") {
        $healthy = $true
        break
    }
    
    Start-Sleep -Seconds 2
}

if (-not $healthy) {
    Write-Host "❌ Database failed to become healthy within timeout" -ForegroundColor Red
    Write-Host "Check logs with: docker-compose logs postgres" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Database is healthy" -ForegroundColor Green

Write-Host "`n🔍 Verifying data load..." -ForegroundColor Cyan

# Wait a bit more for seed script to complete
Start-Sleep -Seconds 5

# Query database to verify records
$query = "SELECT COUNT(*) as count FROM dpp;"
$result = docker-compose exec -T postgres psql -U dpp_sx2ZMqdA -d dpp -t -c $query 2>&1

if ($LASTEXITCODE -eq 0) {
    $count = $result.Trim()
    Write-Host "✅ Database query successful" -ForegroundColor Green
    Write-Host "   Found $count DPP records in database" -ForegroundColor White
    
    if ($count -eq $recordCount) {
        Write-Host "✅ All $recordCount records loaded successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Expected $recordCount records but found $count" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Failed to query database" -ForegroundColor Red
    Write-Host "Error: $result" -ForegroundColor Red
}

Write-Host "`n📊 Sample queries you can run:" -ForegroundColor Cyan
Write-Host ""
Write-Host "# List all DPP records" -ForegroundColor Gray
Write-Host 'docker-compose exec postgres psql -U dpp_sx2ZMqdA -d dpp -c "SELECT dpp_id, product_id FROM dpp;"' -ForegroundColor White
Write-Host ""
Write-Host "# Get finished product" -ForegroundColor Gray
Write-Host 'docker-compose exec postgres psql -U dpp_sx2ZMqdA -d dpp -c "SELECT * FROM dpp WHERE product_id = ''LEGO-DUCK-001'';"' -ForegroundColor White
Write-Host ""
Write-Host "# Get components" -ForegroundColor Gray
Write-Host 'docker-compose exec postgres psql -U dpp_sx2ZMqdA -d dpp -c "SELECT dpp_id, product_id FROM dpp WHERE dpp_id LIKE ''%component%'';"' -ForegroundColor White
Write-Host ""

Write-Host "`n🌐 Testing API endpoints:" -ForegroundColor Cyan

# Wait for API to be ready
Write-Host "   Waiting for API to start..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Test API health
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -ErrorAction Stop
    Write-Host "✅ API health check: OK" -ForegroundColor Green
} catch {
    Write-Host "⚠️  API not responding yet (this is normal, it may still be starting)" -ForegroundColor Yellow
    Write-Host "   Check status with: docker-compose logs api" -ForegroundColor Gray
}

Write-Host "`n🔗 Test these DPP endpoints when API is ready:" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Finished Product (Lego Duck)" -ForegroundColor Gray
Write-Host 'curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:product:lego-duck:item-SN-2025-LD-001234' -ForegroundColor White
Write-Host ""
Write-Host "# Component (Red Brick)" -ForegroundColor Gray
Write-Host 'curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:component:red-brick:batch-2025-Q4-001' -ForegroundColor White
Write-Host ""
Write-Host "# Raw Material (ABS from Thailand)" -ForegroundColor Gray
Write-Host 'curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:raw:abs-th:batch-2025-10-001' -ForegroundColor White
Write-Host ""

Write-Host "`n✅ Migration Complete!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host "`n📚 Documentation:" -ForegroundColor Cyan
Write-Host "   - Seed changes: seed\SEED_CHANGES.md" -ForegroundColor White
Write-Host "   - DPP hierarchy: seed\DPP_HIERARCHY_LEGO_DUCK.md" -ForegroundColor White
Write-Host "   - Master data template: seed\MASTER_DATA_TEMPLATE.md" -ForegroundColor White
Write-Host "   - Quick start: seed\QUICKSTART.md" -ForegroundColor White
Write-Host ""
