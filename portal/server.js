#!/usr/bin/env node
/**
 * Custom server wrapper for Next.js standalone mode
 * This ensures proper port binding for Azure App Service
 */

const { createServer } = require('http');
const { parse } = require('url');
const next = require('next');
const path = require('path');

// Use Azure's PORT environment variable, default to 3000 for local dev
const port = parseInt(process.env.PORT || '3000', 10);
const dev = process.env.NODE_ENV !== 'production';
const hostname = '0.0.0.0'; // Listen on all interfaces for Azure

console.log(`[Server] Starting in ${dev ? 'development' : 'production'} mode`);
console.log(`[Server] Port: ${port}`);
console.log(`[Server] Hostname: ${hostname}`);

// For production with standalone output, use the built standalone server
if (!dev && process.env.NODE_ENV === 'production') {
  const standaloneServerPath = path.join(__dirname, '.next', 'standalone', 'server.js');
  
  try {
    // Set PORT for the standalone server
    process.env.PORT = port.toString();
    
    console.log(`[Server] Loading standalone server from: ${standaloneServerPath}`);
    require(standaloneServerPath);
  } catch (error) {
    console.error('[Server] Failed to load standalone server:', error);
    console.log('[Server] Falling back to standard Next.js server...');
    
    // Fallback to standard Next.js server
    const app = next({ dev, hostname, port });
    const handle = app.getRequestHandler();
    
    app.prepare().then(() => {
      createServer(async (req, res) => {
        try {
          const parsedUrl = parse(req.url, true);
          await handle(req, res, parsedUrl);
        } catch (err) {
          console.error('Error handling request:', err);
          res.statusCode = 500;
          res.end('Internal Server Error');
        }
      }).listen(port, hostname, (err) => {
        if (err) throw err;
        console.log(`[Server] Ready on http://${hostname}:${port}`);
      });
    });
  }
} else {
  // Development mode
  const app = next({ dev, hostname, port });
  const handle = app.getRequestHandler();
  
  app.prepare().then(() => {
    createServer(async (req, res) => {
      try {
        const parsedUrl = parse(req.url, true);
        await handle(req, res, parsedUrl);
      } catch (err) {
        console.error('Error handling request:', err);
        res.statusCode = 500;
        res.end('Internal Server Error');
      }
    }).listen(port, hostname, (err) => {
      if (err) throw err;
      console.log(`[Server] Development server ready on http://${hostname}:${port}`);
    });
  });
}
