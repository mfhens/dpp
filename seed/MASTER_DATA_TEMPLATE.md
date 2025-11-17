# Master Data Template for DPP - Lego Duck Case

## Overview
This template defines the complete master data structure required for Digital Product Passport (DPP) compliance, aligned with prEN 18219, prEN 18221, and EU Battery Regulation 2023/1542 standards.

---

## 1. Material Master (MARA - Material Master Record)

### Required Fields

| Field | Description | Example | DPP Mapping | Required |
|-------|-------------|---------|-------------|----------|
| **Material Number** | Unique material identifier | `LEGO-DUCK-001` | `product.model` | ✅ |
| **Material Type** | Type classification | `FERT` (Finished), `HALB` (Semi-finished), `ROH` (Raw) | `product.category` | ✅ |
| **Description** | Material name | `Lego Duck - Red & Yellow` | `product.description` | ✅ |
| **GTIN** | Global Trade Item Number | `04260012345746` | `product.gtin` | ✅ |
| **Base Unit** | Unit of measure | `PC` (piece), `KG`, `L` | - | ✅ |
| **Material Group** | Product category | `TOYS-LEGO` | `product.category` | ✅ |
| **Gross Weight** | Weight with packaging | `0.125` KG | - | ✅ |
| **Net Weight** | Weight without packaging | `0.095` KG | - | ✅ |
| **Volume** | Cubic measurement | `0.0008` M³ | - | ⚠️ |
| **Created Date** | Creation timestamp | `2025-10-29` | `createdAt` | ✅ |
| **Changed Date** | Last modification | `2025-10-29` | `updatedAt` | ✅ |
| **Manufacturer** | Producer company | `Brickquack A/S` | `provenance.operatorId` | ✅ |
| **Country of Origin** | Primary origin | `DK` (Denmark) | `provenance.countryOfOrigin` | ✅ |

### Material Hierarchy

```
FERT (Finished Goods)
├── LEGO-DUCK-001 (Lego Duck - Assembled)
│
HALB (Semi-Finished / Components)
├── RED-BRICK-001 (Red Plate Brick)
├── YELLOW-BRICK-001 (Yellow Plate Brick)
├── DUCK-EYE-001 (Duck Eye Component)
│
ROH (Raw Materials)
├── ABS-TH-001 (ABS Resin from Thailand)
├── ABS-KW-001 (ABS Resin from Kuwait)
├── CB-LUX-001 (Carbon Black from Luxembourg)
├── PVC-BE-001 (PVC Packaging from Belgium)
└── PAPER-ZA-001 (Paper Packaging from South Africa)
```

---

## 2. Material Composition & Compliance (MARA Extended)

### For Each Material

| Field | Description | Example | DPP Mapping | Required |
|-------|-------------|---------|-------------|----------|
| **Material Composition** | List of constituent materials with % | See table below | `product.identifiers.materials` | ✅ |
| **Recycled Content %** | Percentage of recycled material | `15%` | `circularity.recycledContent` | ✅ |
| **Recyclability %** | Recyclability score | `85%` | `circularity.recyclabilityScore` | ✅ |
| **Hazardous Substances** | REACH SVHC, RoHS substances | See table below | `substancesOfConcern` | ✅ |
| **Carbon Footprint** | kg CO2e per unit | `0.45` | `environmentalFootprint.productCarbonFootprint.value` | ✅ |
| **Water Footprint** | Liters per unit | `12.5` | `environmentalFootprint.waterFootprint` | ✅ |
| **Energy Consumption** | kWh per unit | `1.8` | `environmentalFootprint.energyConsumption` | ✅ |
| **Certifications** | ISO, EN, ASTM certifications | `EN 71-1, EN 71-3, ASTM F963` | `compliance` | ✅ |
| **Repairability Score** | 0-10 scale | `7.5` | `circularity.repairability.score` | ⚠️ |
| **Design for Disassembly** | Boolean | `true` | `circularity.designForDisassembly` | ⚠️ |

### Material Composition Table Template

#### Example: Red Plate Brick (RED-BRICK-001)

| Material Name | Type | Percentage | Origin Country | CAS Number | Certifications | Source Material |
|---------------|------|------------|----------------|------------|----------------|-----------------|
| ABS Resin (Thailand) | Polymer | 47.5% | TH | 9003-56-9 | ISO 9001, RoHS | ABS-TH-001 |
| ABS Resin (Kuwait) | Polymer | 47.5% | KW | 9003-56-9 | ISO 9001, RoHS | ABS-KW-001 |
| Carbon Black | Pigment | 5.0% | LU | 1333-86-4 | REACH Registered | CB-LUX-001 |

#### Example: Finished Lego Duck (LEGO-DUCK-001)

| Component | Material Type | Quantity | Unit | Percentage by Weight | DPP Reference |
|-----------|---------------|----------|------|----------------------|---------------|
| Red Plate Brick | Semi-finished | 6 | PC | 32% | `dpp:red-brick:batch-2025-Q4` |
| Yellow Plate Brick | Semi-finished | 10 | PC | 53% | `dpp:yellow-brick:batch-2025-Q4` |
| Duck Eye | Semi-finished | 2 | PC | 3% | `dpp:duck-eye:batch-2025-Q4` |
| PVC Packaging | Raw material | 1 | PC | 8% | `dpp:pvc-pack:batch-2025-10` |
| Paper Packaging | Raw material | 1 | PC | 4% | `dpp:paper-pack:batch-2025-10` |

---

## 3. Supplier Master (LFA1 - Vendor Master)

| Field | Description | Example | DPP Mapping | Required |
|-------|-------------|---------|-------------|----------|
| **Supplier ID** | Unique vendor number | `1000569` | `provenance.supplierIds[].id` | ✅ |
| **Supplier Name** | Legal entity name | `PolyFormix Global Ltd.` | `provenance.supplierIds[].name` | ✅ |
| **LEI** | Legal Entity Identifier | `549300POLYFORMIX123` | `provenance.supplierIds[].legalEntityIdentifier` | ✅ |
| **Supplier Type** | Category | `Raw Material`, `Component`, `Packaging` | `provenance.supplierIds[].type` | ✅ |
| **Country** | Headquarters location | `AE` (UAE) | - | ✅ |
| **Address** | Full address | `Dubai Industrial City, UAE` | - | ✅ |
| **Contact Email** | Primary contact | `procurement@polyformix.ae` | - | ✅ |
| **Certifications** | Quality/Environmental | `ISO 9001:2015, ISO 14001:2015` | - | ⚠️ |
| **Sustainability Rating** | ESG Score | `B+` (EcoVadis) | - | ⚠️ |
| **Lead Time (Days)** | Average procurement time | `45` | - | ✅ |
| **MOQ** | Minimum Order Quantity | `1000 KG` | - | ✅ |
| **Payment Terms** | Payment conditions | `Net 60` | - | ⚠️ |

### Example Supplier List

| Supplier ID | Name | LEI | Type | Country | Materials Supplied | Lead Time |
|-------------|------|-----|------|---------|-------------------|-----------|
| 1000569 | PolyFormix Global Ltd. | 549300POLYFORMIX123 | Raw Material | AE | ABS-TH-001, ABS-KW-001 | 45 days |
| 1000570 | PetroNovo Materials SA | 549300PETRONOVO456 | Raw Material | LU | CB-LUX-001 | 30 days |
| 1000571 | PackTech Belgium NV | 549300PACKTECH789 | Packaging | BE | PVC-BE-001 | 20 days |
| 1000572 | AfriPack Solutions | 549300AFRIPACK012 | Packaging | ZA | PAPER-ZA-001 | 35 days |

---

## 4. Material-to-Supplier Link (EINA - Purchasing Info Record)

| Field | Description | Example | Required |
|-------|-------------|---------|----------|
| **Material Number** | Material being sourced | `ABS-TH-001` | ✅ |
| **Supplier ID** | Vendor providing material | `1000569` | ✅ |
| **Plant** | Receiving plant | `2001` | ✅ |
| **Supplier Material Number** | Vendor's SKU | `PF-ABS-TH-750` | ⚠️ |
| **Lead Time** | Days from order to delivery | `45` | ✅ |
| **Price** | Per unit cost | `2.50 EUR/KG` | ⚠️ |
| **MOQ** | Minimum order quantity | `1000 KG` | ⚠️ |
| **Valid From** | Price validity start | `2025-01-01` | ⚠️ |
| **Valid To** | Price validity end | `2025-12-31` | ⚠️ |
| **Preferred Supplier** | Primary source flag | `X` (Yes) | ✅ |

---

## 5. Plant & Storage Location (T001L)

| Field | Description | Example | Required |
|-------|-------------|---------|----------|
| **Company Code** | Legal entity code | `2020` | ✅ |
| **Company Name** | Legal entity name | `Brickquack A/S` | ✅ |
| **Plant Code** | Production facility code | `2001` | ✅ |
| **Plant Name** | Facility name | `Billund Manufacturing` | ✅ |
| **Plant GLN** | Global Location Number | `5790002345678` | ✅ |
| **Plant Country** | ISO country code | `DK` | ✅ |
| **Plant Address** | Full address | `Systemvej 1, 7190 Billund, Denmark` | ✅ |
| **Storage Location Code** | Warehouse/area code | `FG01` | ✅ |
| **Storage Location Name** | Warehouse description | `Finished Goods Warehouse` | ✅ |
| **Storage Type** | Classification | `Finished Goods`, `Raw Materials`, `WIP` | ✅ |
| **Capacity** | Storage capacity | `50000 PC` | ⚠️ |

### Corrected Plant/Storage Structure

**Company: 2020 - Brickquack A/S (Denmark)**

#### Plant 2001 - Billund Manufacturing (Denmark)
| Storage Location | Name | Type | Country |
|------------------|------|------|---------|
| DK-FG01 | Billund Finished Goods | Finished Goods | DK |
| DK-RM01 | Billund Raw Materials | Raw Materials | DK |
| DK-WIP01 | Billund Work in Progress | WIP | DK |

#### Plant 2002 - Copenhagen Distribution (Denmark)
| Storage Location | Name | Type | Country |
|------------------|------|------|---------|
| DK-DC01 | Copenhagen Distribution Center | Distribution | DK |

**Company: 2021 - Brickquack Europe GmbH (Germany)**

#### Plant 2101 - Frankfurt Distribution (Germany)
| Storage Location | Name | Type | Country |
|------------------|------|------|---------|
| DE-DC01 | Frankfurt Distribution Center | Distribution | DE |

**Company: 2022 - Brickquack Americas Inc. (USA)**

#### Plant 2201 - Dallas Distribution (USA)
| Storage Location | Name | Type | Country |
|------------------|------|------|---------|
| US-DC01 | Dallas Distribution Center | Distribution | US |

**Company: 2023 - Brickquack Poland Sp. z o.o. (Poland)**

#### Plant 2301 - Krakow Packaging (Poland)
| Storage Location | Name | Type | Country |
|------------------|------|------|---------|
| PL-PKG01 | Krakow Packaging Facility | Packaging | PL |

---

## 6. BOM Structure (MAST - Material BOM Allocation / STPO - BOM Items)

### MAST - BOM Header

| Field | Description | Example | Required |
|-------|-------------|---------|----------|
| **Material Number** | Parent material | `LEGO-DUCK-001` | ✅ |
| **Plant** | Production plant | `2001` | ✅ |
| **BOM Usage** | Purpose | `1` (Production) | ✅ |
| **BOM Number** | Unique BOM ID | `BOM-LD-001` | ✅ |
| **BOM Version** | Version number | `001` | ✅ |
| **Valid From** | Validity start date | `2025-01-01` | ✅ |
| **Valid To** | Validity end date | `9999-12-31` | ✅ |
| **Base Quantity** | Production lot size | `1` PC | ✅ |
| **BOM Status** | Active/Inactive | `1` (Active) | ✅ |

### STPO - BOM Items

| Parent Material | Item Number | Component Material | Quantity | Unit | Scrap % | Valid From | Component Type | DPP Link Required |
|-----------------|-------------|-------------------|----------|------|---------|------------|----------------|-------------------|
| LEGO-DUCK-001 | 0010 | RED-BRICK-001 | 6 | PC | 2% | 2025-01-01 | HALB | ✅ |
| LEGO-DUCK-001 | 0020 | YELLOW-BRICK-001 | 10 | PC | 2% | 2025-01-01 | HALB | ✅ |
| LEGO-DUCK-001 | 0030 | DUCK-EYE-001 | 2 | PC | 1% | 2025-01-01 | HALB | ✅ |
| LEGO-DUCK-001 | 0040 | PVC-BE-001 | 1 | PC | 5% | 2025-01-01 | ROH | ✅ |
| LEGO-DUCK-001 | 0050 | PAPER-ZA-001 | 1 | PC | 3% | 2025-01-01 | ROH | ✅ |
| RED-BRICK-001 | 0010 | ABS-TH-001 | 5.0 | G | 3% | 2025-01-01 | ROH | ✅ |
| RED-BRICK-001 | 0020 | ABS-KW-001 | 5.0 | G | 3% | 2025-01-01 | ROH | ✅ |
| RED-BRICK-001 | 0030 | CB-LUX-001 | 0.5 | G | 1% | 2025-01-01 | ROH | ✅ |
| YELLOW-BRICK-001 | 0010 | ABS-TH-001 | 4.5 | G | 3% | 2025-01-01 | ROH | ✅ |
| YELLOW-BRICK-001 | 0020 | ABS-KW-001 | 4.5 | G | 3% | 2025-01-01 | ROH | ✅ |
| YELLOW-BRICK-001 | 0030 | CB-LUX-001 | 0.3 | G | 1% | 2025-01-01 | ROH | ✅ |
| DUCK-EYE-001 | 0010 | ABS-TH-001 | 1.0 | G | 2% | 2025-01-01 | ROH | ✅ |
| DUCK-EYE-001 | 0020 | CB-LUX-001 | 0.5 | G | 1% | 2025-01-01 | ROH | ✅ |

---

## 7. Plant Data for Material (MARC)

| Field | Description | Example | Required |
|-------|-------------|---------|----------|
| **Material Number** | Material code | `LEGO-DUCK-001` | ✅ |
| **Plant** | Plant code | `2001` | ✅ |
| **MRP Type** | Planning strategy | `PD` (MRP) | ✅ |
| **Lot Size** | Production batch size | `500` PC | ✅ |
| **Procurement Type** | Make or buy | `E` (In-house production) | ✅ |
| **Production Time** | Manufacturing lead time | `2` days | ✅ |
| **Safety Stock** | Minimum inventory | `100` PC | ⚠️ |
| **Reorder Point** | Trigger for procurement | `200` PC | ⚠️ |
| **Max Stock Level** | Maximum inventory | `1000` PC | ⚠️ |
| **ABC Indicator** | Importance classification | `A` (High value) | ⚠️ |

---

## 8. Storage Location Data (MARD)

| Field | Description | Example | Required |
|-------|-------------|---------|----------|
| **Material Number** | Material code | `LEGO-DUCK-001` | ✅ |
| **Plant** | Plant code | `2001` | ✅ |
| **Storage Location** | Storage code | `DK-FG01` | ✅ |
| **Unrestricted Stock** | Available quantity | `450` PC | ✅ |
| **Blocked Stock** | Quality hold | `10` PC | ⚠️ |
| **Quality Inspection** | QA pending | `40` PC | ⚠️ |
| **Last Goods Receipt** | Last receipt date | `2025-10-28` | ⚠️ |
| **Last Goods Issue** | Last issue date | `2025-10-29` | ⚠️ |

---

## 9. DPP-Specific Requirements

### Identification & Granularity

| Field | Description | Values | Example |
|-------|-------------|--------|---------|
| **ID Scheme** | prEN 18219 compliant scheme | `DID_W3C`, `WEB_STRUCTURED_PATH_AI_15459_18975`, `DOI_ISO_26324`, `IEC_61406_IL` | `DID_W3C` |
| **ID Granularity** | Level of uniqueness | `model`, `batch`, `item` | `batch` for components, `item` for finished goods |
| **DPP ID Format** | Structured identifier | DID: `did:web:dpp-brickquack.azurewebsites.net:product:{material}:{id}` | `did:web:dpp-brickquack.azurewebsites.net:product:lego-duck:batch-2025-Q4-001` |

### Document Requirements

| Document Type | Format | Required For | Storage |
|---------------|--------|--------------|---------|
| Safety Data Sheet (SDS) | PDF | Raw materials (chemicals) | Object store + URL in DPP |
| Technical Datasheet | PDF | All materials | Object store + URL in DPP |
| Compliance Certificate | PDF | All materials | Object store + URL in DPP |
| User Manual | PDF | Finished goods | Object store + URL in DPP |
| Declaration of Conformity | PDF | Finished goods (CE marked) | Object store + URL in DPP |
| Test Reports | PDF | Quality-critical components | Object store + URL in DPP |
| Environmental Report | PDF | All materials | Object store + URL in DPP |

---

## 10. Planning & Demand Data (for IBP Integration)

| Field | Description | Example | Unit | Required |
|-------|-------------|---------|------|----------|
| **Forecast Demand** | Expected monthly sales | `10000` | PC/month | ✅ |
| **Seasonal Factor** | Demand variation | `1.5` (Q4), `0.8` (Q1) | Multiplier | ⚠️ |
| **Customer Orders** | Confirmed orders | `8500` | PC | ✅ |
| **Pipeline Stock** | In-transit inventory | `2000` | PC | ⚠️ |
| **Production Capacity** | Max output | `15000` | PC/month | ✅ |
| **Capacity Utilization** | Current usage | `67%` | Percentage | ⚠️ |
| **Supply Risk** | Material availability | `Medium` | Low/Medium/High | ⚠️ |

---

## 11. Checklist for DPP Compliance

### ✅ Core Requirements
- [ ] Unique globally resolvable identifier per prEN 18219
- [ ] ID granularity specified (model/batch/item)
- [ ] Product category defined
- [ ] Provenance data (operator, facility, country of origin)
- [ ] Manufacturing date
- [ ] Material composition with percentages
- [ ] Supplier information with LEI

### ✅ Environmental Requirements
- [ ] Product Carbon Footprint (PCF) calculated
- [ ] Water footprint measured
- [ ] Energy consumption tracked
- [ ] Calculation method documented

### ✅ Circularity Requirements
- [ ] Recyclability score calculated
- [ ] Recycled content percentage
- [ ] Repairability assessment
- [ ] End-of-life instructions
- [ ] Design for disassembly flag

### ✅ Compliance Requirements
- [ ] Substances of concern listed (REACH SVHC, RoHS)
- [ ] Relevant certifications (EN 71 for toys)
- [ ] Compliance schemes documented
- [ ] Validity periods specified

### ✅ Traceability Requirements
- [ ] BOM hierarchy defined
- [ ] Parent-child DPP relationships mapped
- [ ] Component DPPs linked
- [ ] Batch/lot traceability enabled

---

## Next Steps

1. **Fill in the templates** with actual data from your Excel files
2. **Validate geographic consistency** (plant locations match country codes)
3. **Complete BOM structures** for all semi-finished components
4. **Assign unique identifiers** (GTIN, material numbers)
5. **Calculate environmental metrics** (carbon, water, energy)
6. **Map supplier relationships** (who supplies what material)
7. **Generate DPP records** using the sample format provided
8. **Test data quality** by loading into the DPP system

---

## Reference Documents

- **prEN 18219**: Digital Product Passports - Identification scheme
- **prEN 18221**: Digital Product Passports - Data carrier requirements
- **EU Battery Regulation 2023/1542**: Battery passport requirements
- **GS1 Digital Link**: URI syntax for product identification
- **W3C DID**: Decentralized identifier specification
- **ISO/IEC 15459**: Unique identifiers for item management
- **ISO 14067**: Carbon footprint of products
- **EN 71**: Safety of toys (Part 1, 3, 9)
- **ASTM F963**: Standard Consumer Safety Specification for Toy Safety
- **REACH Regulation**: Registration, Evaluation, Authorization of Chemicals
