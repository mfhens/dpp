# Simple Database Reset - Just Clear Data Folder
# This is faster than 'docker-compose down -v' and achieves the same result

Write-Host "`n🔄 Simple Database Reset - Clear Data Folder" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# Check if we're in the correct directory
if (!(Test-Path "compose.yaml")) {
    Write-Host "❌ Error: compose.yaml not found" -ForegroundColor Red
    Write-Host "Please run this script from the dpp project root directory" -ForegroundColor Yellow
    exit 1
}

# Check if data folder exists
if (!(Test-Path "data")) {
    Write-Host "✅ Data folder doesn't exist (already clean)" -ForegroundColor Green
    Write-Host "Just run: docker-compose up -d" -ForegroundColor Cyan
    exit 0
}

# Check current data size
$dataSize = (Get-ChildItem data -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "`n📊 Current data folder size: $([math]::Round($dataSize, 2)) MB" -ForegroundColor Yellow

Write-Host "`n⚠️  This will:" -ForegroundColor Yellow
Write-Host "   1. Stop all services" -ForegroundColor White
Write-Host "   2. Delete the data folder (postgres, minio, immudb, keycloak)" -ForegroundColor White
Write-Host "   3. Restart services with fresh Lego Duck seed data" -ForegroundColor White

$confirm = Read-Host "`nDo you want to continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "`n❌ Operation cancelled" -ForegroundColor Red
    exit 0
}

Write-Host "`n🛑 Step 1: Stopping services..." -ForegroundColor Cyan
docker-compose down

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to stop services" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Services stopped" -ForegroundColor Green

Write-Host "`n🗑️  Step 2: Deleting data folder..." -ForegroundColor Cyan
try {
    Remove-Item -Path "data" -Recurse -Force -ErrorAction Stop
    Write-Host "✅ Data folder deleted" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to delete data folder: $_" -ForegroundColor Red
    Write-Host "You may need to delete it manually" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n🚀 Step 3: Starting services..." -ForegroundColor Cyan
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start services" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Services starting..." -ForegroundColor Green

Write-Host "`n⏳ Waiting for database initialization (this takes ~30-60 seconds)..." -ForegroundColor Cyan
Write-Host "   You can monitor progress with: docker-compose logs -f postgres" -ForegroundColor Gray

# Wait and check health
Start-Sleep -Seconds 10

$maxAttempts = 20
$attempt = 0
while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "   Checking database health ($attempt/$maxAttempts)..." -ForegroundColor Gray
    
    $status = docker-compose ps postgres --format json 2>$null | ConvertFrom-Json
    if ($status.Health -eq "healthy") {
        Write-Host "✅ Database is healthy!" -ForegroundColor Green
        break
    }
    
    Start-Sleep -Seconds 3
}

Write-Host "`n🔍 Verifying Lego Duck data..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

$query = "SELECT COUNT(*) FROM dpp;"
$count = docker-compose exec -T postgres psql -U dpp_sx2ZMqdA -d dpp -t -c $query 2>&1

if ($LASTEXITCODE -eq 0) {
    $recordCount = $count.Trim()
    Write-Host "✅ Found $recordCount DPP records in database" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not verify data yet (database may still be initializing)" -ForegroundColor Yellow
}

Write-Host "`n✅ Reset Complete!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host "`n📝 The database now contains Lego Duck sample DPPs" -ForegroundColor Cyan
Write-Host ""
Write-Host "🧪 Test with:" -ForegroundColor Yellow
Write-Host '   curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:product:lego-duck:item-SN-2025-LD-001234' -ForegroundColor White
Write-Host ""
