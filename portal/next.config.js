/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // IMPORTANT: Do not use standalone output for Azure App Service
  // Azure App Service works best with regular Next.js build
  // Standalone mode causes issues with static asset serving
  output: undefined, // Always use regular build mode
  
  // Ensure proper static asset handling
  assetPrefix: process.env.ASSET_PREFIX || '',
  
  // Ensure proper environment variable handling
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
    NEXT_PUBLIC_API_BASE: process.env.NEXT_PUBLIC_API_BASE,
    API_BASE: process.env.API_BASE,
  },
  
  // Production optimizations
  compress: true,
  poweredByHeader: false,
  
  // Handle dynamic routes properly
  trailingSlash: false,
  
  // Ensure CSS is properly generated and served
  compiler: {
    // Remove console logs in production
    removeConsole: process.env.NODE_ENV === 'production' ? { exclude: ['error', 'warn'] } : false,
  },
};

module.exports = nextConfig;