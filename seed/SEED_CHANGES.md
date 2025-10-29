# Database Seed Changes - Lego Duck Example

## Summary

The database seed configuration has been updated to use the **Lego Duck sample DPP records** instead of the original testdata.

## Changes Made

### ✅ 1. Updated Seed Script

**File**: `seed/postgres/020_seed.sql`

**Changes**:
- Changed data source from `testdata.ndjson` → `lego-duck-sample-dpps.ndjson`
- Updated `product_id` extraction to support the new schema structure:
  - Now extracts from `{product,model}` first (primary for Lego Duck)
  - Falls back to `{product,serialNumber}` or `{product,batchOrLot}`
  - Maintains backward compatibility with old format

**Before**:
```sql
\copy _seed(doc) FROM '/docker-entrypoint-initdb.d/testdata.ndjson'
```

**After**:
```sql
\copy _seed(doc) FROM '/docker-entrypoint-initdb.d/lego-duck-sample-dpps.ndjson'
```

### ✅ 2. Data Backed Up

**Original testdata preserved**: `seed/postgres/testdata.ndjson.backup`

To restore original testdata:
```bash
cd seed/postgres
Copy-Item testdata.ndjson.backup 020_seed.sql
# Then edit 020_seed.sql to point back to testdata.ndjson
```

---

## New Seed Data

### 8 DPP Records

#### Raw Materials (5)
1. **ABS-TH-001** - ABS Resin from Thailand
   - DPP: `did:web:dpp.brickquack.com:raw:abs-th:batch-2025-10-001`
   - Supplier: PolyFormix Global (Thailand)
   
2. **ABS-KW-001** - ABS Resin from Kuwait
   - DPP: `did:web:dpp.brickquack.com:raw:abs-kw:batch-2025-10-002`
   - Supplier: PolyFormix Global (Kuwait)
   
3. **CB-LUX-001** - Carbon Black from Luxembourg
   - DPP: `did:web:dpp.brickquack.com:raw:cb-lux:batch-2025-10-003`
   - Supplier: PetroNovo Materials (Luxembourg)
   
4. **PVC-BE-001** - PVC Packaging from Belgium
   - DPP: `did:web:dpp.brickquack.com:raw:pvc-be:batch-2025-10-004`
   - Supplier: PackTech Belgium
   
5. **PAPER-ZA-001** - Paper Packaging from South Africa
   - DPP: `did:web:dpp.brickquack.com:raw:paper-za:batch-2025-10-005`
   - Supplier: AfriPack Solutions

#### Components (3)
6. **RED-BRICK-001** - Red Plate Brick (2x4 studs)
   - DPP: `did:web:dpp.brickquack.com:component:red-brick:batch-2025-Q4-001`
   - Made from: ABS-TH, ABS-KW, CB-LUX
   
7. **YELLOW-BRICK-001** - Yellow Plate Brick (2x3 studs)
   - DPP: `did:web:dpp.brickquack.com:component:yellow-brick:batch-2025-Q4-001`
   - Made from: ABS-TH, ABS-KW, CB-LUX (yellow pigment)
   
8. **DUCK-EYE-001** - Duck Eye Component
   - DPP: `did:web:dpp.brickquack.com:component:duck-eye:batch-2025-Q4-001`
   - Made from: ABS-TH, CB-LUX

#### Finished Product (1)
9. **LEGO-DUCK-001** - Lego Duck Complete Set
   - DPP: `did:web:dpp.brickquack.com:product:lego-duck:item-SN-2025-LD-001234`
   - Serial: SN-2025-LD-001234
   - Made from: 6× RED-BRICK, 10× YELLOW-BRICK, 2× DUCK-EYE, 1× PVC pack, 1× Paper pack

---

## How to Apply Changes

### Step 1: Stop and Remove Existing Database

```bash
cd c:\Users\AJ849XF\Documents\GitHub\dpp

# Stop all services and remove volumes
docker-compose down -v
```

⚠️ **Warning**: The `-v` flag removes all data volumes. This will delete existing database data.

### Step 2: Start Services

```bash
# Start all services
docker-compose up -d

# Or start just the database
docker-compose up -d postgres

# Wait for database to initialize
docker-compose logs -f postgres
```

Look for: `PostgreSQL init process complete; ready for start up.`

### Step 3: Verify Data Loaded

```bash
# Check database logs
docker-compose logs postgres | Select-String "seed"

# Connect to database
docker-compose exec postgres psql -U dpp_sx2ZMqdA -d dpp

# Query DPP records
SELECT dpp_id, product_id FROM dpp;

# Should see 8 records with Lego Duck DPP IDs
```

### Step 4: Test API

```bash
# Test finished product DPP
curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:product:lego-duck:item-SN-2025-LD-001234

# Test component DPP
curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:component:red-brick:batch-2025-Q4-001

# Test raw material DPP
curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:raw:abs-th:batch-2025-10-001
```

---

## Database Structure

### Tables Populated

#### `dpp` table:
```sql
SELECT * FROM dpp LIMIT 3;
```

Expected output:
```
dpp_id                                                                       | product_id      | dpp_url
-----------------------------------------------------------------------------+-----------------+--------------------------------------------------
did:web:dpp.brickquack.com:raw:abs-th:batch-2025-10-001                     | ABS-TH-001      | http://api:8000/dpp/did:web:dpp.brickquack.com:raw:abs-th:batch-2025-10-001
did:web:dpp.brickquack.com:component:red-brick:batch-2025-Q4-001            | RED-BRICK-001   | http://api:8000/dpp/did:web:dpp.brickquack.com:component:red-brick:batch-2025-Q4-001
did:web:dpp.brickquack.com:product:lego-duck:item-SN-2025-LD-001234         | LEGO-DUCK-001   | http://api:8000/dpp/did:web:dpp.brickquack.com:product:lego-duck:item-SN-2025-LD-001234
```

#### `dpp_version` table:
```sql
SELECT dpp_id, version, payload->>'product' as product FROM dpp_version LIMIT 1;
```

Contains full JSON payload for each DPP.

---

## Example Queries

### Query 1: Get All Components
```sql
SELECT 
  dpp_id,
  payload->'product'->>'model' as model,
  payload->'product'->>'category' as category
FROM dpp_version
WHERE payload->'product'->>'category' = 'component';
```

### Query 2: Get Material Composition
```sql
SELECT 
  payload->'product'->>'model' as product,
  jsonb_array_elements(payload->'product'->'identifiers'->'materials') as material
FROM dpp_version
WHERE dpp_id LIKE '%lego-duck%';
```

### Query 3: Get Supply Chain
```sql
SELECT 
  payload->'product'->>'model' as product,
  jsonb_array_elements(payload->'provenance'->'supplierIds')->>'name' as supplier,
  payload->'provenance'->>'countryOfOrigin' as origin
FROM dpp_version
WHERE payload->'product'->>'category' = 'raw-material';
```

### Query 4: Get BOM Hierarchy
```sql
-- Get finished product and its components
SELECT 
  p.payload->'product'->>'model' as finished_product,
  comp->>'material' as component_code,
  comp->>'quantity' as quantity,
  comp->>'dpp' as component_dpp
FROM dpp_version p,
  jsonb_array_elements(p.payload->'profiles'->'product.bom'->'components') as comp
WHERE p.dpp_id LIKE '%lego-duck:item%';
```

### Query 5: Get Environmental Footprint
```sql
SELECT 
  payload->'product'->>'model' as product,
  payload->'environmentalFootprint'->'productCarbonFootprint'->>'value' as carbon_kg_co2e,
  payload->'environmentalFootprint'->>'waterFootprint' as water_liters,
  payload->'circularity'->>'recyclabilityScore' as recyclability_pct
FROM dpp_version
ORDER BY (payload->'environmentalFootprint'->'productCarbonFootprint'->>'value')::numeric DESC;
```

---

## Troubleshooting

### Issue: No Data Loaded

**Check**:
```bash
# Verify file exists
ls seed/postgres/lego-duck-sample-dpps.ndjson

# Check seed script
cat seed/postgres/020_seed.sql
```

**Solution**: Ensure file path in `020_seed.sql` matches actual file name.

### Issue: Product ID Not Extracted

**Check**:
```sql
SELECT dpp_id, product_id FROM dpp WHERE product_id LIKE 'did:%';
```

If product_id contains full DID (wrong), the COALESCE logic needs adjustment.

**Solution**: The updated script prioritizes `{product,model}` which should work correctly.

### Issue: DPP Records Not Appearing in API

**Check**:
```bash
# Verify API is running
curl http://localhost:8000/health

# Check database connection from API
docker-compose logs api | Select-String "database"
```

**Solution**: Restart API service:
```bash
docker-compose restart api
```

---

## Rollback to Original Testdata

If you need to revert to the original testdata:

### Step 1: Restore Original Seed Script
```bash
cd c:\Users\AJ849XF\Documents\GitHub\dpp\seed\postgres

# Edit 020_seed.sql and change:
# FROM '/docker-entrypoint-initdb.d/lego-duck-sample-dpps.ndjson'
# back to:
# FROM '/docker-entrypoint-initdb.d/testdata.ndjson'
```

### Step 2: Rebuild Database
```bash
cd c:\Users\AJ849XF\Documents\GitHub\dpp
docker-compose down -v
docker-compose up -d
```

---

## Benefits of Lego Duck Sample Data

### ✅ Demonstrates Complete DPP Hierarchy
- Raw materials → Components → Finished product
- Full traceability chain
- Parent-child DPP linking via custom profiles

### ✅ Shows Real-World Supply Chain
- Multiple suppliers across different countries
- Multiple facilities (manufacturing, assembly, QC, packaging)
- International sourcing (Thailand, Kuwait, Luxembourg, Belgium, South Africa)

### ✅ Includes Compliance Data
- Toy safety standards (EN 71, ASTM F963)
- Chemical regulations (REACH, RoHS)
- Substances of concern tracking

### ✅ Environmental & Circularity Metrics
- Carbon footprint calculated at each level
- Water and energy consumption tracked
- Recyclability scores
- Recycled content percentages
- Repairability assessment

### ✅ Production-Ready Schema
- All required fields present
- Valid DID format
- Proper use of profiles for BOM
- Schema-compliant JSON structure

---

## Next Steps

1. ✅ **Test the seed data** - Restart database and verify records
2. ✅ **Query the hierarchy** - Test BOM traversal queries
3. ✅ **Test API endpoints** - Verify DPP retrieval works
4. ⏳ **Add more products** - Create additional Lego products using same structure
5. ⏳ **Implement UI** - Display DPP hierarchy in portal
6. ⏳ **Add QR codes** - Link physical products to DPPs

---

## Related Documentation

- `MASTER_DATA_TEMPLATE.md` - Complete master data specification
- `DPP_HIERARCHY_LEGO_DUCK.md` - Visual hierarchy and usage guide
- `QUICKSTART.md` - Implementation guide
- `lego-duck-sample-dpps.ndjson` - The actual DPP records

---

**Date Updated**: 2025-10-29
**Status**: ✅ Ready for deployment
