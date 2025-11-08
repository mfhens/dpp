# POC Demo Scripts - Quick Start

## For Azure Deployment (Current Setup)

Your POC is running on Azure App Services. Use these scripts:

### 1. Reset Database to Known State
```powershell
.\reset-demo-database-azure.ps1
```
- Clears all data from Azure SQL Database via API
- Reloads Lego Duck sample data (9 products)
- Verifies data is ready
- **Time:** ~30 seconds

### 2. Run Interactive Demo
```powershell
.\demo-poc-azure.ps1
```
- Walks through complete POC flow
- Shows finding DPP and viewing data
- Provides instructions for uploading planning insights via Portal
- All steps explained on screen
- **Time:** ~5-10 minutes

### 3. Upload Planning Insights (Manual)
- Open Portal: https://dpp-brickquack.azurewebsites.net/upload
- Upload CSV: `seed\SSCP1__PRODLOCLOCFR_DEMO.csv`
- See **[Upload Guide](docs/UPLOAD-PLANNING-INSIGHTS.md)** for details

### 4. Open in Browser
- **Portal:** https://dpp-brickquack.azurewebsites.net
- **API Docs:** https://dpp-brickquack-api.azurewebsites.net/docs
- **API Health:** https://dpp-brickquack-api.azurewebsites.net/health

---

## Files Created

| File | Purpose |
|------|---------|
| `reset-demo-database-azure.ps1` | Reset Azure database via API |
| `demo-poc-azure.ps1` | Interactive demo script for Azure |
| `seed\SSCP1__PRODLOCLOCFR_DEMO.csv` | Sample planning insights data (10 records, 4 products) |
| `docs\POC-DEMO-GUIDE-AZURE.md` | Complete guide for non-tech users |
| `docs\UPLOAD-PLANNING-INSIGHTS.md` | Guide for uploading CSV data via Portal or API |

---

## Typical Demo Flow

1. **Before the demo:**
   ```powershell
   .\reset-demo-database-azure.ps1
   ```

2. **During the demo:**
   ```powershell
   .\demo-poc-azure.ps1
   ```
   Follow on-screen prompts

3. **Show in browser (optional):**
   - Open https://dpp-brickquack.azurewebsites.net
   - Search for Lego Duck
   - Show the updated planning insights

---

## Azure Services Used

- **API:** https://dpp-brickquack-api.azurewebsites.net
- **Portal:** https://dpp-brickquack.azurewebsites.net
- **Resource Group:** dpp-brickquack
- **Database:** Azure SQL Database

---

## Troubleshooting

### API Not Responding
```powershell
# Check status
az webapp show --name dpp-brickquack-api --resource-group dpp-brickquack

# View logs
az webapp log tail --name dpp-brickquack-api --resource-group dpp-brickquack

# Restart if needed
az webapp restart --name dpp-brickquack-api --resource-group dpp-brickquack
```

### Data Not Loading
```powershell
# Reset and reload
.\reset-demo-database-azure.ps1
```

---

## What Non-Tech Users Need

Give them these two things:
1. This file (POC-DEMO-SCRIPTS-README.md)
2. The detailed guide: `docs\POC-DEMO-GUIDE-AZURE.md`

They can then:
- Reset the database before demos
- Run the interactive demo
- Present confidently to stakeholders

---

## CSV Upload Mechanism

The demo uses the API to upload planning insights:

```
CSV File → Parse → Build JSON → PATCH /dpp/{id} → Updated DPP
```

**Sample CSV:**
- `seed\SSCP1__PRODLOCLOCFR_DEMO.csv`
- Contains transport and carbon data for 4 products
- 10 location records total

**Products in CSV:**
- LEGO-DUCK (4 locations)
- RED-PLATE-BRICK (2 locations)
- YELLOW-PLATE-BRICK (2 locations)
- DUCK-EYE (2 locations)

---

## Key Features Demonstrated

1. **DPP Retrieval**
   - REST API: `GET /dpp/{id}`
   - Shows complete product information
   - Includes materials, environmental data, compliance

2. **Planning Insights Upload**
   - REST API: `PATCH /dpp/{id}`
   - Processes CSV data
   - Updates multiple products
   - Shows optimization metrics

3. **Real-Time Updates**
   - Fetch updated DPP
   - Shows new planning insights
   - Displays transport savings
   - Shows carbon reductions

---

## Sample Data Hierarchy

```
Lego Duck (Finished Product)
├── Component: Red Plate Brick (6 pieces)
│   ├── Raw: ABS01 Thailand (5g)
│   ├── Raw: ABS02 Kuwait (5g)
│   └── Raw: CB01 Carbon Black (0.5g)
├── Component: Yellow Plate Brick (10 pieces)
│   ├── Raw: ABS01 Thailand (4.5g)
│   ├── Raw: ABS02 Kuwait (4.5g)
│   └── Raw: CB01 Carbon Black (0.3g)
├── Component: Duck Eye (2 pieces)
│   ├── Raw: ABS01 Thailand (1g)
│   └── Raw: CB01 Carbon Black (0.5g)
├── Packaging: PVC01 Film
└── Packaging: PB01 Paper Box
```

All products have DPPs and can be queried individually.

---

## For More Information

- **Non-tech guide:** `docs\POC-DEMO-GUIDE-AZURE.md` (comprehensive)
- **Technical docs:** `Readme.md` (architecture, setup)
- **API docs:** `api\README.md` (deployment, endpoints)
- **Sample data:** `seed\DPP_HIERARCHY_LEGO_DUCK.md` (full hierarchy)

---

*Created: 2025-11-08*
*For: Azure-hosted POC demonstration*
