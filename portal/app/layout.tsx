import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "DPP Portal",
  description: "Digital Product Passport demo portal"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header className="border-b border-white/10">
          <div className="mx-auto max-w-5xl px-4 py-4 flex items-center justify-between">
            <a href="/" className="font-semibold">DPP Portal</a>
            <nav className="text-sm">
              <a href="/dpp" className="opacity-80 hover:opacity-100">Browse</a>
            </nav>
          </div>
        </header>
        <main className="mx-auto max-w-5xl px-4 py-6">{children}</main>
      </body>
    </html>
  );
}
