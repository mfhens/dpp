"use client";

import { useState } from "react";

export default function Home() {
  const [id, setId] = useState("");

  function go(e: React.FormEvent) {
    e.preventDefault();
    if (!id) return;
    window.location.href = `/dpp/${encodeURIComponent(id)}`;
  }

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-semibold">Digital Product Passport</h1>
      <p className="opacity-80 max-w-2xl">
        Enter a DPP ID to view its current version. The details page supports time travel with the <code>?at=</code> query.
      </p>

      <form onSubmit={go} className="flex gap-2 max-w-xl">
        <input
          className="flex-1 rounded-xl bg-white/5 border border-white/10 px-3 py-2 outline-none focus:border-white/30"
          placeholder="Paste a DPP ID UUID here"
          value={id}
          onChange={e => setId(e.target.value)}
        />
        <button
          className="rounded-xl px-4 py-2 bg-white text-black font-medium hover:bg-gray-100"
          type="submit"
        >
          Open
        </button>
      </form>

      <div className="text-sm opacity-80">
        Try reading a DPP at <code>/dpp/&lt;id&gt;</code> or add <code>?at=2025-08-01T12:00:00Z</code>.
      </div>
    </div>
  );
}
