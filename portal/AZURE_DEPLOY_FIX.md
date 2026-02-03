# Azure Deployment Fix for Portal

## Problem
The portal fails to start with error: `Cannot find module 'next'`

## Root Cause
Azure's Oryx build system builds the app during deployment, but the `node_modules` directory isn't being properly preserved or accessible at runtime.

## Solution

### Step 1: Configure Azure App Service Settings
Run these commands in Azure CLI or Cloud Shell:

```bash
# Set resource group and app name
RESOURCE_GROUP="dpp-brickquack"
APP_NAME="dpp-brickquack"

# Configure App Settings
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --settings \
    SCM_DO_BUILD_DURING_DEPLOYMENT=true \
    WEBSITE_NODE_DEFAULT_VERSION="~20" \
    NODE_ENV=production \
    NPM_CONFIG_PRODUCTION=false \
    WEBSITE_RUN_FROM_PACKAGE=0 \
    ENABLE_ORYX_BUILD=true \
    POST_BUILD_COMMAND="ls -la && ls -la node_modules | head -20" \
    PRE_BUILD_COMMAND="echo 'Starting build...'"

# Set startup command
az webapp config set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --startup-file "bash startup.sh"
```

### Step 2: Deploy from VS Code
1. Right-click on the `portal` folder
2. Select "Deploy to Web App..."
3. Choose your app service: `dpp-brickquack`
4. Wait for deployment to complete (3-5 minutes)

### Step 3: Monitor the Deployment
```bash
# Watch the build logs
az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP
```

### Step 4: Verify Deployment
Check these endpoints:
- Portal: https://dpp-brickquack.azurewebsites.net
- Kudu (Advanced Tools): https://dpp-brickquack.scm.azurewebsites.net

In Kudu, go to "Debug console" > "CMD" and verify:
```bash
cd /home/site/wwwroot
ls -la
ls -la node_modules | head -20
ls -la node_modules/next
```

## Alternative: Include node_modules in Deployment

If the above doesn't work, you can deploy WITH node_modules:

### Option A: Build locally and deploy
1. In VS Code terminal (in portal folder):
   ```powershell
   npm ci --production=false
   npm run build
   ```

2. Create `.vscode/settings.json` in the portal folder:
   ```json
   {
     "appService.zipIgnorePattern": [
       ".git*",
       ".vscode",
       "*.md",
       "oryx-manifest.toml"
     ],
     "appService.deploySubpath": "."
   }
   ```

3. Deploy from VS Code (this will include node_modules)

### Option B: Use standalone build (Docker-style)
1. Update `next.config.js` to enable standalone:
   ```javascript
   output: 'standalone'
   ```

2. Build locally:
   ```powershell
   npm run build
   ```

3. Deploy the `.next/standalone` folder instead

## Troubleshooting

### Check if node_modules exists
SSH into the App Service and run:
```bash
cd /home/site/wwwroot
ls -la
du -sh node_modules
```

### Force a clean deployment
1. In Azure Portal, go to your App Service
2. Development Tools > Advanced Tools > Go
3. In Kudu, go to Site wwwroot
4. Delete everything
5. Redeploy from VS Code

### Check environment variables
In Kudu console:
```bash
printenv | grep -E "NODE|NPM|ORYX|WEBSITE"
```

## Expected Behavior After Fix
The startup logs should show:
```
✅ node_modules directory found
✅ Next.js package verified
✅ Build directory found
Using regular Next.js production server
✅ 'next' module loaded successfully
✅ Ready on http://0.0.0.0:8080
```
