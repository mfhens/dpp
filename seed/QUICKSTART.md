# Quick Start Guide - Lego Duck DPP Templates

## 📦 What You Got

Three comprehensive documents for implementing DPP for the Lego Duck case:

1. **MASTER_DATA_TEMPLATE.md** - Complete data model specification
2. **lego-duck-sample-dpps.ndjson** - 8 ready-to-use DPP records
3. **DPP_HIERARCHY_LEGO_DUCK.md** - Visual hierarchy & usage guide

---

## 🚀 Quick Start

### Step 1: Review the Master Data Template

Open `MASTER_DATA_TEMPLATE.md` and understand:

- ✅ Material Master structure (MARA)
- ✅ BOM hierarchy (MAST/STPO)
- ✅ Supplier master (LFA1)
- ✅ Plant & storage locations (T001L)
- ✅ DPP-specific requirements
- ✅ Compliance checklist

### Step 2: Fix Your Excel Files

Based on the critical issues identified, update your Excel files:

#### **Fix 1: Geographic Consistency**

❌ **Current** (WRONG):
```
Company: Brickquack (2020)
  Plant: Billund (2001)
    Storage: Krakow SL (PL01) ← Poland under Denmark plant!
    Storage: Frankfurt SL (GE01) ← Germany under Denmark plant!
  Plant: Monterry (2002)
    Storage: Dallas SL (US02) ← USA under Mexico plant!
    Storage: Toronto SL (TO02) ← Canada under Mexico plant!
```

✅ **Should be** (CORRECT):
```
Company: Brickquack Denmark (2020)
  Plant: Billund Manufacturing (2001) - DENMARK
    Storage: DK-FG01 (Finished Goods)
    Storage: DK-RM01 (Raw Materials)

Company: Brickquack Europe GmbH (2021)
  Plant: Frankfurt Distribution (2101) - GERMANY
    Storage: DE-DC01 (Distribution)

Company: Brickquack Americas (2022)
  Plant: Dallas Distribution (2201) - USA
    Storage: US-DC01 (Distribution)

Company: Brickquack Poland (2023)
  Plant: Krakow Packaging (2301) - POLAND
    Storage: PL-PKG01 (Packaging)
```

#### **Fix 2: Complete the BOM**

Add to `BrickQuack_STPO_Link BOM to Components.xlsx`:

| Parent Material | Component | Quantity | Unit | Notes |
|-----------------|-----------|----------|------|-------|
| YELLOW-BRICK-001 | ABS-TH-001 | 4.5 | G | Thailand resin |
| YELLOW-BRICK-001 | ABS-KW-001 | 4.5 | G | Kuwait resin |
| YELLOW-BRICK-001 | CB-LUX-001 | 0.3 | G | Yellow pigment (carbon black base) |
| DUCK-EYE-001 | ABS-TH-001 | 1.0 | G | Thailand resin |
| DUCK-EYE-001 | CB-LUX-001 | 0.5 | G | Black pigment |

#### **Fix 3: Material-to-Supplier Mapping**

Add to `BrickQuack_EINA_Material linked to supplier.xlsx`:

| Material | Supplier ID | Supplier Name | Lead Time | MOQ | Price |
|----------|-------------|---------------|-----------|-----|-------|
| ABS-TH-001 | 1000569 | PolyFormix Global | 45 days | 1000 KG | 2.50 EUR/KG |
| ABS-KW-001 | 1000569 | PolyFormix Global | 45 days | 1000 KG | 2.50 EUR/KG |
| CB-LUX-001 | 1000570 | PetroNovo Materials | 30 days | 500 KG | 3.80 EUR/KG |
| PVC-BE-001 | 1000571 | PackTech Belgium | 20 days | 5000 PC | 0.08 EUR/PC |
| PAPER-ZA-001 | 1000572 | AfriPack Solutions | 35 days | 10000 PC | 0.05 EUR/PC |

#### **Fix 4: Add Material Master Data**

Create new file: `BrickQuack_MARA_Material_Master.xlsx`

Required columns:
- Material Number (e.g., LEGO-DUCK-001)
- GTIN (e.g., 04260012345838)
- Description
- Material Type (FERT/HALB/ROH)
- Base Unit (PC/KG/G)
- Gross Weight
- Net Weight
- Country of Origin

#### **Fix 5: Add Supplier Details**

Update `BrickQuack_LFA1_Supplier list.xlsx` with:

| Supplier ID | Name | LEI | Country | Address | Certifications |
|-------------|------|-----|---------|---------|----------------|
| 1000569 | PolyFormix Global Ltd. | 549300POLYFORMIX123 | AE | Dubai Industrial City, UAE | ISO 9001, ISO 14001 |
| 1000570 | PetroNovo Materials SA | 549300PETRONOVO456 | LU | Esch-sur-Alzette, Luxembourg | ISO 9001, REACH |
| 1000571 | PackTech Belgium NV | 549300PACKTECH789 | BE | Antwerp, Belgium | ISO 9001, EN 13432 |
| 1000572 | AfriPack Solutions | 549300AFRIPACK012 | ZA | Cape Town, South Africa | ISO 9001, FSC |

---

## 🧪 Test the Sample DPPs

### Option 1: Load into Database

```bash
# Navigate to project directory
cd c:\Users\AJ849XF\Documents\GitHub\dpp

# Backup existing testdata
cp seed\postgres\testdata.ndjson seed\postgres\testdata.ndjson.backup

# Replace with Lego Duck samples
cp seed\postgres\lego-duck-sample-dpps.ndjson seed\postgres\testdata.ndjson

# Restart containers to reload data
docker-compose down -v
docker-compose up -d

# Wait for services to start, then test
curl http://localhost:8000/dpp/did:web:dpp-brickquack.azurewebsites.net:product:lego-duck:item-SN-2025-LD-001234
```

### Option 2: Append to Existing Data

```bash
# Add Lego Duck samples to existing testdata
cat seed\postgres\lego-duck-sample-dpps.ndjson >> seed\postgres\testdata.ndjson

# Restart to reload
docker-compose restart postgres
docker-compose restart api
```

---

## 📊 Validate Your Data

### Checklist for Each Material

Use this checklist when filling out master data:

#### ✅ Basic Information
- [ ] Unique material number assigned
- [ ] GTIN generated (if applicable)
- [ ] Clear description in English
- [ ] Material type specified (FERT/HALB/ROH)
- [ ] Base unit of measure defined

#### ✅ Physical Properties
- [ ] Gross weight measured
- [ ] Net weight measured
- [ ] Volume calculated (for logistics)
- [ ] Dimensions specified

#### ✅ Provenance
- [ ] Country of origin identified
- [ ] Manufacturing facility specified (GLN)
- [ ] Supplier(s) assigned
- [ ] Legal Entity Identifier (LEI) for manufacturer

#### ✅ Composition
- [ ] Material composition list with percentages (must sum to 100%)
- [ ] Origin country per material component
- [ ] CAS numbers for chemicals
- [ ] Certifications documented

#### ✅ Environmental Data
- [ ] Carbon footprint calculated (kg CO2e)
- [ ] Water footprint measured (liters)
- [ ] Energy consumption tracked (kWh)
- [ ] Calculation method documented

#### ✅ Circularity
- [ ] Recyclability score assessed
- [ ] Recycled content percentage
- [ ] Repairability score (if applicable)
- [ ] End-of-life instructions provided

#### ✅ Compliance
- [ ] Relevant regulations identified (EN 71, RoHS, REACH)
- [ ] Substances of concern listed
- [ ] Certifications obtained
- [ ] Test reports available

#### ✅ BOM Linkages
- [ ] Parent materials identified
- [ ] Component quantities specified
- [ ] DPP links prepared (will be generated)

---

## 🎯 DPP Generation Workflow

### For Each Material:

1. **Collect Data** → Fill Excel templates
2. **Validate** → Use checklist above
3. **Generate DPP ID** → Follow naming convention
4. **Create DPP Record** → Use sample format
5. **Link to Components** → Add DPP references
6. **Review** → Check against schema
7. **Load** → Import into database

### DPP ID Naming Convention

```
did:web:dpp-brickquack.azurewebsites.net:{type}:{material}:{granularity}-{id}

Examples:
- Raw material: did:web:dpp-brickquack.azurewebsites.net:raw:abs-th:batch-2025-10-001
- Component: did:web:dpp-brickquack.azurewebsites.net:component:red-brick:batch-2025-Q4-001
- Product: did:web:dpp-brickquack.azurewebsites.net:product:lego-duck:item-SN-2025-LD-001234
```

**Rules**:
- Use lowercase with hyphens
- Include type (raw/component/product)
- Include granularity (batch-X or item-X)
- Ensure globally unique

---

## 🔍 Sample Queries

### Query 1: Get Full Product Hierarchy

```sql
-- Get the finished product
WITH product AS (
  SELECT dpp_id, payload
  FROM dpp_version
  WHERE dpp_id LIKE '%lego-duck%'
),
-- Extract component references
components AS (
  SELECT 
    p.dpp_id as product_id,
    jsonb_array_elements(p.payload->'profiles'->'product.bom'->'components') as comp
  FROM product p
)
-- Get component details
SELECT 
  c.product_id,
  c.comp->>'material' as component_code,
  c.comp->>'dpp' as component_dpp,
  c.comp->>'quantity' as quantity
FROM components c;
```

### Query 2: Calculate Total Carbon Footprint

```sql
SELECT 
  payload->>'product'->>'model' as material,
  (payload->'environmentalFootprint'->'productCarbonFootprint'->>'value')::numeric as pcf,
  payload->>'product'->>'category' as category
FROM dpp_version
WHERE dpp_id LIKE '%dpp-brickquack.azurewebsites.net%'
ORDER BY pcf DESC;
```

### Query 3: Find Materials from Specific Supplier

```sql
SELECT 
  dpp_id,
  payload->'product'->>'model' as material,
  jsonb_array_elements(payload->'provenance'->'supplierIds')->>'name' as supplier
FROM dpp_version
WHERE payload->'provenance'->'supplierIds' @> '[{"name": "PolyFormix Global Ltd."}]';
```

---

## 🐛 Troubleshooting

### Issue: DPP ID not resolving

**Cause**: DPP URL not accessible or ID format incorrect

**Fix**:
1. Verify ID follows schema: `did:web:dpp-brickquack.azurewebsites.net:...`
2. Check `dppUrl` field matches: `http://api:8000/dpp/{dpp_id}`
3. Ensure record loaded in database

### Issue: Material composition doesn't sum to 100%

**Cause**: Rounding errors or missing components

**Fix**:
1. List all materials with percentages
2. Sum should equal exactly 100.0%
3. Adjust largest component to balance

### Issue: Schema validation fails

**Cause**: Missing required fields

**Fix**:
1. Check against `schemas/core/1-0-0.schema.json`
2. Ensure all required fields present:
   - id, idScheme, idGranularity
   - schemaVersion, dppUrl
   - product, provenance
3. Validate JSON format

### Issue: BOM links broken

**Cause**: Component DPP doesn't exist

**Fix**:
1. Create DPPs in bottom-up order:
   - Raw materials first
   - Components second
   - Finished products last
2. Verify DPP IDs match exactly

---

## 📝 Next Actions

### Immediate (This Week)
1. [ ] Fix geographic issues in T001L Excel file
2. [ ] Complete BOM for Yellow Brick and Duck Eye
3. [ ] Add material-to-supplier mappings
4. [ ] Create Material Master Excel file

### Short-term (This Month)
5. [ ] Calculate carbon footprints for all materials
6. [ ] Obtain supplier certifications and LEIs
7. [ ] Generate GTINs for all products
8. [ ] Create test DPPs for first production batch

### Medium-term (This Quarter)
9. [ ] Integrate with ERP system
10. [ ] Set up automated DPP generation
11. [ ] Create consumer QR codes
12. [ ] Train staff on DPP processes

---

## 💡 Tips

**Tip 1**: Start with one complete product
- Pick the simplest product (e.g., Red Brick)
- Complete all data for it
- Generate and test its DPP
- Use as template for others

**Tip 2**: Use batch processing
- Group similar materials together
- Fill data in batches (all raw materials, then all components)
- Generate DPPs in batches
- Validate in batches

**Tip 3**: Maintain data quality
- Single source of truth (Excel or database, not both)
- Version control for Excel files (Git)
- Regular audits of data completeness
- Automated validation scripts

**Tip 4**: Plan for scale
- Current: 1 product (Lego Duck)
- Next: Product family (all Brickquack animals)
- Future: Full catalog (all products)

---

## 📚 Reference Documents

| Document | Purpose | Location |
|----------|---------|----------|
| Master Data Template | Data model specification | `seed/MASTER_DATA_TEMPLATE.md` |
| DPP Hierarchy | Visual guide & examples | `seed/DPP_HIERARCHY_LEGO_DUCK.md` |
| Sample DPPs | 8 ready-to-use records | `seed/postgres/lego-duck-sample-dpps.ndjson` |
| DPP Schema | JSON Schema validation | `schemas/core/1-0-0.schema.json` |
| Database Schema | PostgreSQL tables | `seed/postgres/001_schema.sql` |

---

## 🤝 Need Help?

Common questions:

**Q: How do I generate a GTIN?**
A: Use GS1 GTIN generator or apply for GS1 company prefix. For testing, use format `04260012345XXX`.

**Q: Where do I get LEI for suppliers?**
A: Check https://search.gleif.org/ or ask suppliers directly. For testing, use format `549300XXXXXXXXXX`.

**Q: How do I calculate carbon footprint?**
A: Use ISO 14067 methodology, supplier data, or tools like SimaPro. For testing, use industry averages.

**Q: What if I don't have all data yet?**
A: Start with what you have. Mark estimated values clearly. Improve data quality iteratively.

**Q: Can I modify the schema?**
A: The core schema should remain compatible with standards. Add custom profiles in the `profiles` section.

---

## ✅ Success Criteria

You'll know you're ready when:

1. ✅ All Excel files validated with checklist
2. ✅ Geographic consistency fixed
3. ✅ Complete BOM for all components
4. ✅ Material-to-supplier mappings complete
5. ✅ Sample DPP loads without errors
6. ✅ DPP hierarchy traverses correctly
7. ✅ Environmental data calculated
8. ✅ Compliance certifications documented

---

**Good luck! 🎉**

Remember: DPP is a journey, not a destination. Start simple, iterate, improve. The templates give you a solid foundation to build upon.
