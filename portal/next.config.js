/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Enable standalone output for optimal Azure App Service deployment
  output: 'standalone',
  // Ensure proper environment variable handling
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
    NEXT_PUBLIC_API_BASE: process.env.NEXT_PUBLIC_API_BASE,
  },
  // Production optimizations
  compress: true,
  poweredByHeader: false,
  // Handle dynamic routes properly
  trailingSlash: false,
};

module.exports = nextConfig;