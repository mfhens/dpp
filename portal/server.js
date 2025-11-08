#!/usr/bin/env node
/**
 * Custom server for Next.js on Azure App Service
 * Handles both development and production modes with proper static file serving
 */

const { createServer } = require('http');
const { parse } = require('url');
const path = require('path');
const fs = require('fs');

// Use Azure's PORT environment variable, default to 3000 for local dev
const port = parseInt(process.env.PORT || '3000', 10);
const dev = process.env.NODE_ENV !== 'production';
const hostname = '0.0.0.0'; // Listen on all interfaces for Azure

console.log(`[Server] ========================================`);
console.log(`[Server] DPP Portal Server Starting`);
console.log(`[Server] ========================================`);
console.log(`[Server] Mode: ${dev ? 'development' : 'production'}`);
console.log(`[Server] Port: ${port}`);
console.log(`[Server] Hostname: ${hostname}`);
console.log(`[Server] Working directory: ${process.cwd()}`);
console.log(`[Server] Node version: ${process.version}`);
console.log(`[Server] Platform: ${process.platform}`);

// Check if .next directory exists
const nextBuildPath = path.join(__dirname, '.next');
if (!fs.existsSync(nextBuildPath)) {
  console.error(`[Server] ❌ FATAL: .next build directory not found at ${nextBuildPath}`);
  console.error(`[Server] Please ensure 'npm run build' was executed successfully`);
  process.exit(1);
}
console.log(`[Server] ✅ Build directory found: ${nextBuildPath}`);

// Check if BUILD_ENV is set to 'docker' (only for Docker container builds)
const isDockerBuild = process.env.BUILD_ENV === 'docker';
const standaloneServerPath = path.join(__dirname, '.next', 'standalone', 'server.js');
const isStandaloneBuild = fs.existsSync(standaloneServerPath);

console.log(`[Server] Docker build mode: ${isDockerBuild}`);
console.log(`[Server] Standalone build exists: ${isStandaloneBuild}`);

if (!dev && isDockerBuild && isStandaloneBuild) {
  // Docker/Standalone mode: use the standalone server (only when explicitly built for Docker)
  console.log(`[Server] Using standalone build (Docker mode)`);
  console.log(`[Server] ========================================`);
  process.env.PORT = port.toString();
  process.env.HOSTNAME = hostname;
  require(standaloneServerPath);
} else {
  // Regular Next.js mode (development or Azure App Service)
  console.log(`[Server] Using regular Next.js ${dev ? 'development' : 'production'} server`);
  
  // Check if node_modules exists
  const nodeModulesPath = path.join(__dirname, 'node_modules');
  if (!fs.existsSync(nodeModulesPath)) {
    console.error(`[Server] ❌ FATAL: node_modules directory not found at ${nodeModulesPath}`);
    console.error(`[Server] Dependencies must be installed before starting the server`);
    process.exit(1);
  }
  console.log(`[Server] ✅ node_modules directory found`);
  
  // Check if 'next' package exists
  const nextPackagePath = path.join(__dirname, 'node_modules', 'next');
  if (!fs.existsSync(nextPackagePath)) {
    console.error(`[Server] ❌ FATAL: 'next' package not found at ${nextPackagePath}`);
    console.error(`[Server] Run 'npm install' to install dependencies`);
    console.error(`[Server] Contents of node_modules:`);
    try {
      const contents = fs.readdirSync(nodeModulesPath).slice(0, 20);
      console.error(`[Server] ${contents.join(', ')}...`);
    } catch (e) {
      console.error(`[Server] Could not read node_modules: ${e.message}`);
    }
    process.exit(1);
  }
  console.log(`[Server] ✅ 'next' package found`);
  console.log(`[Server] ========================================`);
  
  let next;
  try {
    next = require('next');
    console.log(`[Server] ✅ 'next' module loaded successfully`);
  } catch (err) {
    console.error(`[Server] ❌ FATAL: Failed to require 'next':`, err);
    console.error(`[Server] Module paths:`, module.paths);
    process.exit(1);
  }
  
  const app = next({ dev, hostname, port });
  const handle = app.getRequestHandler();
  
  app.prepare()
    .then(() => {
      createServer(async (req, res) => {
        try {
          const parsedUrl = parse(req.url, true);
          await handle(req, res, parsedUrl);
        } catch (err) {
          console.error('[Server] Error handling request:', err);
          res.statusCode = 500;
          res.end('Internal Server Error');
        }
      }).listen(port, hostname, (err) => {
        if (err) {
          console.error('[Server] ❌ Failed to listen:', err);
          throw err;
        }
        console.log(`[Server] ✅ Ready on http://${hostname}:${port}`);
        console.log(`[Server] Health check: Server is responding`);
      });
    })
    .catch((err) => {
      console.error('[Server] ❌ Fatal error during startup:', err);
      console.error('[Server] Stack trace:', err.stack);
      process.exit(1);
    });
}

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('[Server] ❌ Uncaught Exception:', err);
  console.error('[Server] Stack trace:', err.stack);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('[Server] ❌ Unhandled Rejection at:', promise);
  console.error('[Server] Reason:', reason);
  process.exit(1);
});
