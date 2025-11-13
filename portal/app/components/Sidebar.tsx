"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, BarChart3, Paperclip, Settings, Upload } from "lucide-react";

const navItems = [
  { href: "/", label: "Landing", icon: Home },
  { href: "/dashboard", label: "Dashboard", icon: BarChart3 },
  { href: "/upload", label: "Upload", icon: Upload },
  { href: "/attachments", label: "Attachments", icon: Paperclip },
  { href: "/settings", label: "Settings", icon: Settings },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-full lg:w-64 bg-[#1e1e1e] text-white flex lg:flex-col">
      <div className="p-4 lg:p-6 font-bold text-lg lg:text-xl border-b lg:border-b border-gray-700 flex-shrink-0">
        EY DPP
      </div>
      <nav className="flex lg:flex-1 overflow-x-auto lg:overflow-x-visible p-2 lg:p-4 gap-2 lg:flex-col lg:space-y-2">
        {navItems.map(({ href, label, icon: Icon }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              /* force white text & no underline; yellow when active */
              className={`flex items-center gap-2 lg:gap-3 px-3 py-2 rounded-lg transition no-underline whitespace-nowrap flex-shrink-0
                ${active
                  ? "bg-[#FFD500] text-black font-semibold"
                  : "text-white hover:bg-gray-800"}`}
            >
              <Icon className="w-5 h-5 flex-shrink-0" />
              <span className="hidden sm:inline">{label}</span>
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
