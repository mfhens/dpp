"use client";

import { useState } from "react";
import Link from "next/link";

export default function Home() {
  const [id, setId] = useState("");

  function go(e: React.FormEvent) {
    e.preventDefault();
    if (!id.trim()) return;
    window.location.href = `/dpp/${encodeURIComponent(id.trim())}`;
  }

  return (
    <main className="ey-container ey-section">
      <header className="ey-section">
        <h1 className="text-3xl ey-stripe">Digital Product Passport</h1>
        <p className="mt-3 text-base text-neutral-600 max-w-2xl">
          Enter a DPP ID to view its current version. The details page supports time travel with the{" "}
          <code>?at=</code> query parameter.
        </p>
      </header>

      <section className="ey-card ey-section p-4 md:p-6">
        <form onSubmit={go} className="grid gap-3 md:grid-cols-[1fr_auto] md:items-center">
          <label htmlFor="dpp-id" className="sr-only">DPP ID</label>
          <input
            id="dpp-id"
            className="ey-input"
            placeholder="Paste a DPP ID (URI/URN/URL)"
            value={id}
            onChange={(e) => setId(e.target.value)}
            autoComplete="off"
            inputMode="text"
          />
          <button type="submit" className="ey-btn ey-btn--primary">Open</button>
        </form>

        <div className="mt-3 text-sm text-neutral-600">
          Try: <code>/dpp/&lt;id&gt;</code> or add{" "}
          <code>?at=2025-08-01T12:00:00Z</code>.
        </div>
      </section>

      <section className="ey-section">
        <h2 className="ey-stripe text-xl mb-3">Quick tips</h2>
        <ul className="list-disc pl-6 text-sm text-neutral-700 space-y-1">
          <li>IDs should be resolvable URIs as per prEN 18219/ISO/IEC 18975.</li>
          <li>Public view is accessible without login; private data requires auth.</li>
        </ul>
      </section>
    </main>
  );
}
