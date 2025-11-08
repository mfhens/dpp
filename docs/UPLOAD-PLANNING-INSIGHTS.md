# Upload Planning Insights - Quick Guide

This guide shows how to manually upload planning insights CSV data to update Digital Product Passports.

## 📋 Overview

The CSV file contains location-specific supply chain data:
- Transport optimization quantities
- Carbon footprint measurements
- Location routing information

## 🎯 Quick Steps

### Option 1: Via Portal (Easiest)

1. **Open the Portal**
   ```
   https://dpp-brickquack.azurewebsites.net/upload
   ```

2. **Upload the CSV file**
   - Navigate to Upload page
   - Select file: `seed\SSCP1__PRODLOCLOCFR_DEMO.csv`
   - Click Upload

3. **Verify Upload**
   - View any DPP (e.g., LEGO-DUCK)
   - Check for updated planning insights

### Option 2: Via API (Advanced)

For each product in the CSV:

1. **Get Current DPP**
   ```powershell
   $dppId = "did:web:dpp-brickquack.azurewebsites.net:product:lego-duck:item-sn-2025-ld-001234"
   $current = Invoke-RestMethod -Uri "https://dpp-brickquack-api.azurewebsites.net/dpp/$dppId"
   ```

2. **Merge Planning Insights**
   ```powershell
   # Get current payload
   $payload = $current.payload
   
   # Add/update planning insights
   $payload.planningInsights = @{
       locations = @(
           @{
               locationFrom = "DK01"
               locationId = "US-EAST"
               adjustedTransportQuantity = 850
               standardTransportQuantity = 1000
               previousTransportFootprint = 45.5
               currentTransportFootprint = 38.2
           }
       )
       transportOptimization = "Optimized routes achieving 150 unit reduction"
       carbonFootprintReduction = "16% reduction in transport emissions"
   }
   ```

3. **Create New Version**
   ```powershell
   $newVersion = @{
       payload = $payload
   } | ConvertTo-Json -Depth 20
   
   Invoke-RestMethod `
       -Uri "https://dpp-brickquack-api.azurewebsites.net/dpp/$dppId/versions" `
       -Method Post `
       -Body $newVersion `
       -ContentType "application/json"
   ```

## 📊 CSV Format

**File:** `seed\SSCP1__PRODLOCLOCFR_DEMO.csv`

**Delimiter:** Semicolon (`;`)

**Columns:**
- `PRDID` - Product ID (matches DPP model field)
- `LOCFR` - Location From (source)
- `LOCID` - Location ID (destination)
- `ADJUSTEDTRANSPORT` - Optimized transport quantity
- `TRANSPORT` - Standard transport quantity
- `SC1STOREDPREVTRANSPFOOTPRFINAL` - Previous carbon footprint
- `SC1STOREDTRANSPFOOTPRFINAL` - Current carbon footprint

**Example:**
```csv
PRDID;LOCFR;LOCID;ADJUSTEDTRANSPORT;TRANSPORT;SC1STOREDPREVTRANSPFOOTPRFINAL;SC1STOREDTRANSPFOOTPRFINAL
LEGO-DUCK;DK01;US-EAST;850;1000;45.5;38.2
LEGO-DUCK;DK01;US-WEST;650;800;52.3;44.8
RED-PLATE-BRICK;DK01;EU-CENTRAL;1200;1400;28.4;24.1
```

## 🎯 Products in Demo CSV

The demo CSV contains data for:
- **LEGO-DUCK** - 2 locations (US-EAST, US-WEST)
- **RED-PLATE-BRICK** - 3 locations (EU-CENTRAL, ASIA-PAC, US-EAST)
- **YELLOW-PLATE-BRICK** - 3 locations (EU-CENTRAL, ASIA-PAC, US-EAST)
- **DUCK-EYE** - 2 locations (EU-CENTRAL, US-EAST)

**Total:** 10 records across 4 products

## 🔍 Verifying Upload

After upload, check a DPP:

```powershell
$dppId = "did:web:dpp-brickquack.azurewebsites.net:product:lego-duck:item-sn-2025-ld-001234"
$response = Invoke-RestMethod -Uri "https://dpp-brickquack-api.azurewebsites.net/dpp/$dppId"

# Check for planning insights
$response.payload.planningInsights
```

You should see:
- ✅ `locations` array with route data
- ✅ `transportOptimization` summary
- ✅ `carbonFootprintReduction` info

## 💡 Tips

1. **Demo Mode**: The API is in `DEMO_MODE=true` for easy testing (no authentication required)

2. **Version History**: Each upload creates a new version, preserving history:
   ```powershell
   # View version history
   GET /dpp/{dpp_id}/versions
   ```

3. **Batch Processing**: Process all products in CSV at once via Portal upload

4. **Data Validation**: Portal validates CSV format before processing

## 🔧 Troubleshooting

### "Method Not Allowed" Error
- API doesn't support PATCH
- Use POST to `/dpp/{dpp_id}/versions` instead

### "DPP Not Found"
- Check DPP ID is lowercase: `did:web:...item-sn-2025...` (not `SN`)
- Verify product exists: `GET /dpp/{dpp_id}`

### "Missing bearer token"
- Ensure `DEMO_MODE=true` is set in Azure App Service settings
- Check: `az webapp config appsettings list --name dpp-brickquack-api --resource-group dpp-brickquack`

## 📖 Related Documentation

- **[POC Demo Guide](POC-DEMO-GUIDE-AZURE.md)** - Complete demo walkthrough
- **[Quick Reference](POC-DEMO-SCRIPTS-README.md)** - Script reference
- **[API Documentation](https://dpp-brickquack-api.azurewebsites.net/docs)** - OpenAPI docs

## 🚀 Quick Test

Run the complete demo to see the flow:

```powershell
.\demo-poc-azure.ps1
```

This will:
1. Check services are running
2. Show how to find a DPP
3. Display upload instructions (this guide)
4. Show the DPP with current data
