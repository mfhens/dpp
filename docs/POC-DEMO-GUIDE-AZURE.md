# 🎯 POC Demo Guide for Non-Technical Users (Azure Deployment)

## Overview

This guide walks you through demonstrating the Digital Product Passport (DPP) system **running on Microsoft Azure**. The demo shows how to:
1. View a product's digital passport hosted in the cloud
2. Upload planning insights data via API
3. See the updated product information in real-time

**Time required:** 10-15 minutes  
**Technical knowledge:** None required!  
**Internet required:** Yes (services run on Azure)

---

## What's Different from Local Setup

This demo uses Azure cloud services instead of running everything on your computer:
- ✅ **API:** Hosted on Azure App Service (always available)
- ✅ **Portal:** Hosted on Azure App Service (accessible from anywhere)
- ✅ **Database:** Azure SQL Database (persistent, backed up)
- ❌ **No local servers** needed - just PowerShell and internet

---

## Prerequisites

Before starting the demo, make sure you have:
- ✅ Windows computer with PowerShell
- ✅ Internet connection
- ✅ This repository downloaded to your computer
- ✅ Azure services are deployed and running

---

## Quick Start (2 Steps!)

### Step 1: Reset to Clean State

Open PowerShell in the project folder and run:

```powershell
.\reset-demo-database-azure.ps1
```

**What this does:** Clears any old data in Azure and loads fresh sample data via API.

**Expected output:** 
```
✅ API is responding
✅ Deleted X DPPs
✅ LEGO-DUCK uploaded
✅ Database reset complete
```

**Time:** ~30 seconds

---

### Step 2: Run the Demo

In the same PowerShell window, run:

```powershell
.\demo-poc-azure.ps1
```

**What this does:** Walks you through the complete demo with clear instructions at each step.

**Follow the prompts:** The script will pause and show you what's happening. Just press any key to continue.

**Time:** ~10 minutes

---

## What the Demo Shows

### Part 1: Check Azure Services
- Verifies API is responding (https://dpp-brickquack-api.azurewebsites.net)
- Checks Portal availability (https://dpp-brickquack.azurewebsites.net)
- Shows both services are running in the cloud

### Part 2: Find a Product Passport
- Retrieves the Lego Duck product from Azure database
- Displays materials, environmental footprint, compliance certificates
- Notes that planning insights are currently empty

### Part 3: Upload Planning Data
- Takes a CSV file with transport optimization data
- Sends it to the Azure API via REST calls
- Updates multiple products in real-time

### Part 4: View Updated Passport
- Fetches the same product again from Azure
- Now includes planning insights:
  - Transport optimization savings (e.g., "530 units reduction")
  - Carbon footprint reductions per location
  - Location-specific logistics data

---

## Manual Steps (If You Want More Control)

If you prefer to run each step manually instead of using the automated demo:

### 1. View a Product in Browser

Open your web browser and go to:
```
https://dpp-brickquack.azurewebsites.net
```

Search for or paste this DPP ID:
```
did:web:dpp-brickquack.azurewebsites.net:product:lego-duck:item-SN-2025-LD-001234
```

### 2. View via API (PowerShell)

```powershell
$apiUrl = "https://dpp-brickquack-api.azurewebsites.net"
$dppId = "did:web:dpp-brickquack.azurewebsites.net:product:lego-duck:item-SN-2025-LD-001234"
Invoke-RestMethod -Uri "$apiUrl/dpp/$dppId" | ConvertTo-Json -Depth 10
```

### 3. Upload Planning Insights

Use the demo script or manually call the API:

```powershell
# See demo-poc-azure.ps1 for the full upload logic
.\demo-poc-azure.ps1
```

---

## Troubleshooting

### "API is NOT responding"
**Symptoms:** Script says API at https://dpp-brickquack-api.azurewebsites.net is not responding

**Solutions:**
1. Check if the App Service is running:
   ```powershell
   az webapp show --name dpp-brickquack-api --resource-group dpp-brickquack
   ```

2. View logs to see what's wrong:
   ```powershell
   az webapp log tail --name dpp-brickquack-api --resource-group dpp-brickquack
   ```

3. Restart the App Service:
   ```powershell
   az webapp restart --name dpp-brickquack-api --resource-group dpp-brickquack
   ```

### "DPP not found" or "Failed to retrieve DPP"
**Symptoms:** Error when trying to view Lego Duck

**Solution:** Reset the database first
```powershell
.\reset-demo-database-azure.ps1
```

### "Failed to upload planning insights"
**Symptoms:** CSV upload fails or no products updated

**Possible causes:**
- Database is empty (run reset script)
- Product IDs in CSV don't match database
- API endpoint is down

**Solution:**
1. Run reset script
2. Check API health: https://dpp-brickquack-api.azurewebsites.net/health
3. Try the demo again

### "Deployment failed" when updating code
**Symptoms:** When running `.\deploy-to-azure.ps1` or `.\deploy-portal-to-azure.ps1`

**Solutions:**
1. Check you're logged into Azure:
   ```powershell
   az login
   ```

2. Verify resource group exists:
   ```powershell
   az group show --name dpp-brickquack
   ```

3. Check deployment logs:
   ```powershell
   az webapp log deployment show --name dpp-brickquack-api --resource-group dpp-brickquack
   ```

### Script shows "Not logged in to Azure"
**Solution:**
```powershell
az login
```
Follow the prompts to authenticate.

---

## Understanding the Output

### During Reset
```
✅ API is responding
   Found 15 existing DPPs
   ✅ Deleted: LEGO-DUCK
   ...
   ✅ LEGO-DUCK
   ✅ RED-PLATE-BRICK
   ...
📊 Results:
   Uploaded: 9 records
```
**Meaning:** Old data removed from Azure, fresh sample data loaded via API.

### During Demo - Viewing DPP
```
📋 Product Information:
   Model: LEGO-DUCK
   Description: Lego Duck - Build & Play Set - Red and Yellow
   ...
📊 Planning Insights (BEFORE):
   ⚠️  No planning insights yet
```
**Meaning:** Product exists in Azure database but doesn't have planning data yet.

### During Demo - Upload
```
   Processing: LEGO-DUCK...
   ✅ LEGO-DUCK updated
   Processing: RED-PLATE-BRICK...
   ✅ RED-PLATE-BRICK updated
   ...
✅ Planning insights uploaded!
   Updated: 4 products
```
**Meaning:** CSV processed, products updated in Azure via API calls.

### During Demo - After Update
```
📊 Planning Insights (AFTER):
   🚚 Transport Optimization:
      Optimized transport routes achieving 530 quantity units reduction...
   
   📍 Location Details:
      Location: US-EAST
         Transport: 850 (was 1000)
         Savings: 150 units (15.0%)
         Footprint: -7.3 (-16.0%)
```
**Meaning:** Planning insights now visible in the Azure-hosted product passport!

---

## Sample Data in the Demo

The demo includes these products (stored in Azure SQL Database):

| Product | ID | Type | API Endpoint |
|---------|-----|------|-------------|
| Lego Duck | LEGO-DUCK | Finished Product | `GET /dpp/did:web:dpp-brickquack.azurewebsites.net:product:lego-duck:item-SN-2025-LD-001234` |
| Red Plate Brick | RED-PLATE-BRICK | Component | `GET /dpp/did:web:dpp-brickquack.azurewebsites.net:component:red-plate-brick:batch-2025-Q4-001` |
| Yellow Plate Brick | YELLOW-PLATE-BRICK | Component | `GET /dpp/did:web:dpp-brickquack.azurewebsites.net:component:yellow-plate-brick:batch-2025-Q4-001` |
| Duck Eye | DUCK-EYE | Component | `GET /dpp/did:web:dpp-brickquack.azurewebsites.net:component:duck-eye:batch-2025-Q4-001` |
| ABS Resin (Thailand) | ABS01 | Raw Material | `GET /dpp/did:web:dpp-brickquack.azurewebsites.net:raw:abs01:batch-2025-10-001` |

---

## Preparing for a Live Demo

### Before the Meeting (5 minutes before)

1. **Test Azure services are up**
   ```powershell
   # Quick health check
   Invoke-RestMethod -Uri "https://dpp-brickquack-api.azurewebsites.net/health"
   ```
   Should return: `{"status":"healthy"}`

2. **Reset the database**
   ```powershell
   .\reset-demo-database-azure.ps1
   ```
   Wait for: `✅ DATABASE RESET COMPLETE`

3. **Test in browser**
   - Open: https://dpp-brickquack.azurewebsites.net
   - Verify it loads

### During the Meeting

**Recommended Approach - Automated:**
```powershell
.\demo-poc-azure.ps1
```
Just follow the on-screen prompts. The script handles everything.

**Alternative - Manual in Browser:**
1. Show the portal: https://dpp-brickquack.azurewebsites.net
2. Search for Lego Duck DPP
3. Run the upload script in another window
4. Refresh browser to show updates

### After the Meeting

No cleanup needed! The data persists in Azure for the next demo.

To reset for the next demo:
```powershell
.\reset-demo-database-azure.ps1
```

---

## Tips for a Great Demo

1. **Practice first!** Run through the demo 2-3 times to get familiar
2. **Test connectivity** - make sure you have stable internet
3. **Have the Portal open** - https://dpp-brickquack.azurewebsites.net is more visual
4. **Know the URLs** - write them down if needed:
   - API: https://dpp-brickquack-api.azurewebsites.net
   - Portal: https://dpp-brickquack.azurewebsites.net
   - API Docs: https://dpp-brickquack-api.azurewebsites.net/docs
5. **Explain the cloud aspect** - "This is running in Microsoft Azure, so it's available 24/7 from anywhere"

---

## What to Say During the Demo

### When viewing the initial DPP:
> "This is our Lego Duck product passport, stored in Microsoft Azure. You can see all its materials, environmental impact, and certifications. Right now, there's no planning data - we'll add that next."

### When uploading the CSV:
> "Now I'm uploading logistics data from our planning system directly to the Azure API. This includes transport routes and carbon footprint calculations. The API processes this in real-time."

### When showing the updated DPP:
> "Look - the product passport now shows optimized transport routes and carbon savings. This information is immediately available to anyone with internet access. It's stored securely in Azure and backed up automatically."

---

## Advantages of Azure Deployment

Explain these benefits during the demo:

- **Always Available:** Services run 24/7 in the cloud
- **Accessible Anywhere:** View from office, home, or mobile
- **Scalable:** Can handle many users simultaneously  
- **Secure:** Industry-standard Azure security
- **Backed Up:** Data is automatically backed up
- **No Installation:** Users just need a web browser

---

## Azure Resources Used

For technical stakeholders, the demo uses:

| Resource | Azure Service | Purpose |
|----------|---------------|---------|
| API | App Service (Linux) | REST API for DPP operations |
| Portal | App Service (Node.js) | Web interface for browsing DPPs |
| Database | SQL Database | Stores DPP records and versions |
| Monitoring | Application Insights | Tracks performance and errors |

**Resource Group:** `dpp-brickquack`  
**Region:** (as configured in your deployment)

---

## Next Steps After the Demo

### For Business Users:
- Explore other products in the portal
- Try searching by different criteria
- Understand the data structure

### For Technical Users:
- View API documentation: https://dpp-brickquack-api.azurewebsites.net/docs
- Test API endpoints with Postman
- Review Azure resource configuration
- Understand deployment pipeline

### For Decision Makers:
- Discuss integration with existing systems
- Plan data migration strategy
- Review security and compliance requirements
- Estimate scaling needs

---

## Customizing for Your Demo

### Using Your Own Data

1. Edit `seed\SSCP1__PRODLOCLOCFR_DEMO.csv`
2. Add your product IDs and data
3. Run reset script to load it
4. Run demo with your data

### Using Different Azure URLs

If you deployed to different App Services:

```powershell
.\demo-poc-azure.ps1 `
    -ApiUrl "https://your-api.azurewebsites.net" `
    -PortalUrl "https://your-portal.azurewebsites.net"
```

---

## Quick Reference Card

Print this and keep it handy:

```
┌─────────────────────────────────────────┐
│  DPP POC DEMO - AZURE QUICK REFERENCE   │
├─────────────────────────────────────────┤
│ 1. RESET DATABASE                       │
│    .\reset-demo-database-azure.ps1      │
│                                         │
│ 2. RUN DEMO                             │
│    .\demo-poc-azure.ps1                 │
│                                         │
│ 3. VIEW IN BROWSER                      │
│    https://dpp-brickquack.              │
│          azurewebsites.net              │
│                                         │
│ 4. CHECK API HEALTH                     │
│    https://dpp-brickquack-api.          │
│          azurewebsites.net/health       │
│                                         │
│ 5. VIEW API DOCS                        │
│    https://dpp-brickquack-api.          │
│          azurewebsites.net/docs         │
└─────────────────────────────────────────┘
```

---

## Frequently Asked Questions

**Q: How long does the demo take?**  
A: 10-15 minutes for the full automated demo, 5 minutes if you just show the highlights.

**Q: Do I need Azure credentials?**  
A: Only if you're resetting data or redeploying. Viewing the demo just needs the URLs.

**Q: Can multiple people run this demo at once?**  
A: Yes! Everyone can access the same Azure services simultaneously.

**Q: What if I accidentally delete all the data?**  
A: Just run `.\reset-demo-database-azure.ps1` to reload the sample data.

**Q: Can I run this demo offline?**  
A: No, it requires internet to access Azure services. Use the local deployment guide instead.

**Q: How much does Azure cost for this?**  
A: Depends on your pricing tier. Basic App Services start around $50/month. SQL Database varies.

**Q: Is the data persistent?**  
A: Yes! Data stays in Azure SQL Database until you delete it.

**Q: Can I access this from my phone?**  
A: Yes! The portal works on mobile browsers: https://dpp-brickquack.azurewebsites.net

---

## Success Checklist

Before your demo, verify:

- [ ] Azure API responds: https://dpp-brickquack-api.azurewebsites.net/health
- [ ] Azure Portal loads: https://dpp-brickquack.azurewebsites.net
- [ ] `.\reset-demo-database-azure.ps1` completes successfully
- [ ] You can view Lego Duck in browser
- [ ] `.\demo-poc-azure.ps1` runs without errors
- [ ] Planning insights appear after upload
- [ ] You can explain what's happening at each step

If all checkboxes are ✅, you're ready to demo!

---

## Monitoring and Logs

### View Real-Time Logs

```powershell
# API logs
az webapp log tail --name dpp-brickquack-api --resource-group dpp-brickquack

# Portal logs
az webapp log tail --name dpp-brickquack --resource-group dpp-brickquack
```

### Check Service Status

```powershell
# API status
az webapp show --name dpp-brickquack-api --resource-group dpp-brickquack --query "state"

# Portal status
az webapp show --name dpp-brickquack --resource-group dpp-brickquack --query "state"
```

### Restart if Needed

```powershell
# Restart API
az webapp restart --name dpp-brickquack-api --resource-group dpp-brickquack

# Restart Portal
az webapp restart --name dpp-brickquack --resource-group dpp-brickquack
```

---

## Support and Help

- **Script issues:** Check the error message and try the troubleshooting section above
- **Azure issues:** View logs with `az webapp log tail...`
- **Data issues:** Run `.\reset-demo-database-azure.ps1`
- **Can't find files:** Make sure you're in the project root directory
- **Technical questions:** See the main `Readme.md` and `api/README.md`

---

## Comparison: Local vs Azure

| Aspect | Local (run-local.ps1) | Azure (this guide) |
|--------|----------------------|-------------------|
| **Setup time** | 30 seconds | Already deployed |
| **Internet required** | No | Yes |
| **Accessibility** | Only your computer | Anywhere with internet |
| **Data persistence** | Until you restart | Permanent (until deleted) |
| **Multi-user** | No | Yes |
| **For demos** | Quick testing | Professional presentations |

Choose **Local** for: Development, quick testing, no internet  
Choose **Azure** for: Demos, production, multi-user access

---

*Last updated: 2025-11-08*  
*For local deployment guide, see: docs/POC-DEMO-GUIDE.md (when created)*  
*For technical documentation, see: Readme.md*
