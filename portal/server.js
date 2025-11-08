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

console.log(`[Server] Starting in ${dev ? 'development' : 'production'} mode`);
console.log(`[Server] Port: ${port}`);
console.log(`[Server] Hostname: ${hostname}`);
console.log(`[Server] Working directory: ${process.cwd()}`);

// Check if BUILD_ENV is set to 'docker' (only for Docker container builds)
const isDockerBuild = process.env.BUILD_ENV === 'docker';
const standaloneServerPath = path.join(__dirname, '.next', 'standalone', 'server.js');
const isStandaloneBuild = fs.existsSync(standaloneServerPath);

if (!dev && isDockerBuild && isStandaloneBuild) {
  // Docker/Standalone mode: use the standalone server (only when explicitly built for Docker)
  console.log(`[Server] Using standalone build (Docker mode)`);
  process.env.PORT = port.toString();
  process.env.HOSTNAME = hostname;
  require(standaloneServerPath);
} else {
  // Regular Next.js mode (development or Azure App Service)
  console.log(`[Server] Using regular Next.js ${dev ? 'development' : 'production'} server`);
  
  const next = require('next');
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
        if (err) throw err;
        console.log(`[Server] ✓ Ready on http://${hostname}:${port}`);
      });
    })
    .catch((err) => {
      console.error('[Server] Failed to start:', err);
      process.exit(1);
    });
}
