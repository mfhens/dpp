# Duck JSON Test Data Alignment with Excel Master Files

## Summary
Updated `seed/postgres/lego-duck-sample-dpps.ndjson` to be consistent with the Excel master data files.

## Changes Made

### 1. Material Codes Updated
**Before:** Used descriptive codes like `ABS-TH-001`, `ABS-KW-001`, `CB-LUX-001`, `PVC-BE-001`, `PAPER-ZA-001`  
**After:** Aligned with Excel codes: `ABS01`, `ABS02`, `CB01`, `PVC01`, `PB01`

### 2. Component Names Updated
**Before:**
- `RED-BRICK-001`
- `YELLOW-BRICK-001`
- `DUCK-EYE-001`
- `LEGO-DUCK-001`

**After:**
- `RED-PLATE-BRICK`
- `YELLOW-PLATE-BRICK`
- `DUCK-EYE`
- `LEGO-DUCK`

### 3. Supplier Information Corrected

| Supplier ID | Excel Name | JSON Name (Before) | JSON Name (After) | Country |
|-------------|------------|-------------------|------------------|---------|
| 1000569 | PolyFormix Global | PolyFormix Global Ltd. | PolyFormix Global | TH |
| 1000570 | PetroNovo Materials | PetroNovo Materials SA | PetroNovo Materials | KW |
| 1000571 | Brussels PVC Packaging | PackTech Belgium NV | Brussels PVC Packaging | BE |
| 1000572 | Cape Town Paper Based Packaging | AfriPack Solutions | Cape Town Paper Based Packaging | ZA |
| 1000573 | Carbon Engineering | *(not in JSON)* | Carbon Engineering | LU |

### 4. Supplier Mapping Fixed

**Carbon Black (CB01):**
- **Before:** Incorrectly mapped to supplier 1000570 (PetroNovo Materials)
- **After:** Correctly mapped to supplier 1000573 (Carbon Engineering)

**ABS from Kuwait (ABS02):**
- **Before:** Had wrong operator and supplier (PolyFormix)
- **After:** Correctly mapped to supplier 1000570 (PetroNovo Materials) with correct LEI

### 5. BOM References Updated
All BOM component references updated to use the new material codes:
- `ABS-TH-001` → `ABS01`
- `ABS-KW-001` → `ABS02`
- `CB-LUX-001` → `CB01`
- `PVC-BE-001` → `PVC01`
- `PAPER-ZA-001` → `PB01`
- `RED-BRICK-001` → `RED-PLATE-BRICK`
- `YELLOW-BRICK-001` → `YELLOW-PLATE-BRICK`
- `DUCK-EYE-001` → `DUCK-EYE`

### 6. DPP IDs and URLs Updated
All DPP identifiers and URLs updated to reflect the new naming convention for consistency across the system.

## Validation

All changes have been validated against the Excel master files:
- ✓ BrickQuack_LFA1_Supplier list.xlsx
- ✓ BrickQuack_EINA_Material linked to supplier.xlsx
- ✓ BrickQuack_MAST_Link Material to BOM.xlsx
- ✓ BrickQuack_STPO_Link BOM to Components.xlsx
- ✓ BrickQuack_T001L_Plant & Storage Location.xlsx

## Impact

These changes ensure:
1. **Consistency** between JSON test data and Excel master data
2. **Correct supplier relationships** for all materials
3. **Accurate BOM structure** matching the master data templates
4. **Proper traceability** through the supply chain
5. **Data integrity** for Digital Product Passport compliance

## Files Modified
- `seed/postgres/lego-duck-sample-dpps.ndjson` (all 9 DPP records updated)

## Date
October 30, 2025
