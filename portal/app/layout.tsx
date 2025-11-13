import "./globals.css";
import type { Metadata } from "next";
import Sidebar from "./components/Sidebar";

export const metadata: Metadata = {
  title: "DPP Portal",
  description: "Digital Product Passport demo portal",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="font-sans">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0" />
      </head>
      {/* Make body a horizontal flex container and full height */}
      <body className="min-h-screen flex flex-col lg:flex-row bg-[var(--ey-surface)] text-[var(--ey-text)]">
        <Sidebar />
        <main className="flex-1 min-h-screen p-4 sm:p-6 lg:p-8 overflow-x-hidden">
          {children}
        </main>
      </body>
    </html>
  );
}
