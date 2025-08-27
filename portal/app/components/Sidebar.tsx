"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, BarChart3, Paperclip, Settings } from "lucide-react";

const navItems = [
  { href: "/", label: "Landing", icon: Home },
  { href: "/dashboard", label: "Dashboard", icon: BarChart3 },
  { href: "/attachments", label: "Attachments", icon: Paperclip },
  { href: "/settings", label: "Settings", icon: Settings },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 min-h-screen bg-[#1e1e1e] text-white flex flex-col">
      <div className="p-6 font-bold text-xl border-b border-gray-700">
        EY DPP
      </div>
      <nav className="flex-1 p-4 space-y-2">
        {navItems.map(({ href, label, icon: Icon }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              /* force white text & no underline; yellow when active */
              className={`flex items-center gap-3 px-3 py-2 rounded-lg transition no-underline
                ${active
                  ? "bg-[#FFD500] text-black font-semibold"
                  : "text-white hover:bg-gray-800"}`}
            >
              <Icon className="w-5 h-5" />
              <span>{label}</span>
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
