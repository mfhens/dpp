export const dynamic = "force-dynamic";

import type { ReactNode } from "react";

type PillTone = "default" | "green" | "amber" | "blue";
type ApiDpp = { dpp_id: string; version: number; payload: unknown };

// --- Fetcher ---
async function getDpp(id: string, at?: string) {
  const base = process.env.API_BASE || "http://localhost:8000";
  const u = new URL(`${base}/dpp/${id}`);
  if (at) u.searchParams.set("at", at);
  const res = await fetch(u.toString(), { headers: { "x-access-tier": "public" }, cache: "no-store" });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`API error ${res.status}`);
  return (await res.json()) as ApiDpp;
}

// --- Payload types ---
type DppPayload = {
  id?: string;
  schemaVersion?: string;
  dppUrl?: string;
  registryId?: string;
  createdAt?: string;
  updatedAt?: string;
  product?: { category?: string; model?: string; batchOrLot?: string; serialNumber?: string; gtin?: string; description?: string };
  provenance?: { operatorId?: string; facilityId?: string; countryOfOrigin?: string; manufactureDate?: string };
  compliance?: Array<{ scheme: string; reference: string; validFrom?: string; validTo?: string }>;
  documents?: Array<{ type: string; url: string; hash?: string; mime?: string }>;
  profiles?: Record<string, { _profile?: { namespace: string; version: string }; [k: string]: unknown }>;
};

function fmtDate(s?: string) {
  if (!s) return "—";
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? s : d.toISOString().replace(".000Z", "Z");
}

// --- EY Components ---
function KVP({ label, value }: { label: string; value?: string | number | boolean }) {
  return (
    <div className="ey-kv">
      <div className="ey-kv__label">{label}</div>
      <div className="ey-kv__value">{value ?? "—"}</div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="ey-card ey-section p-5">
      <h2 className="ey-stripe text-lg font-semibold mb-3">{title}</h2>
      {children}
    </section>
  );
}

function Pill({ children, tone = "default" }: { children: ReactNode; tone?: PillTone }) {
  const tones: Record<PillTone, string> = {
    default: "ey-pill",
    green: "ey-pill bg-emerald-100 text-emerald-800 border-emerald-200",
    amber: "ey-pill bg-amber-100 text-amber-900 border-amber-200",
    blue: "ey-pill bg-blue-100 text-blue-900 border-blue-200",
  };
  return <span className={tones[tone]}>{children}</span>;
}

function CardList({ items }: { items: Array<{ label: string; value?: string | ReactNode }> }) {
  return (
    <div className="grid md:grid-cols-2 gap-4">
      {items.map((it, i) => (
        <div key={i} className="ey-card p-3">
          <div className="text-xs text-neutral-500">{it.label}</div>
          <div className="text-sm break-words">{it.value ?? "—"}</div>
        </div>
      ))}
    </div>
  );
}

// --- Page ---
export default async function Page({ params, searchParams }: { params: { id: string }; searchParams?: { at?: string } }) {
  const data = await getDpp(params.id, searchParams?.at);
  if (!data) return <div className="p-6">DPP not found</div>;

  const p = (data.payload ?? {}) as DppPayload;

  return (
    <div className="ey-container space-y-6 py-6">
      {/* Header */}
      <header className="ey-section">
        <h1 className="text-2xl font-bold">Digital Product Passport</h1>
        <div className="flex flex-wrap items-center gap-2 text-sm text-neutral-600 mt-1">
          <span>ID:</span>
          <code className="ey-chip">{data.dpp_id}</code>
          <span>•</span>
          <span>Version</span>
          <Pill tone="blue">v{data.version}</Pill>
          {p.schemaVersion && (
            <>
              <span>•</span>
              <span>Schema</span>
              <Pill>{p.schemaVersion}</Pill>
            </>
          )}
        </div>
      </header>

      {/* Identity & Access */}
      <Section title="Identity & Access">
        <KVP label="Canonical ID" value={p.id} />
        <KVP label="DPP URL" value={p.dppUrl} />
        <KVP label="Registry ID" value={p.registryId} />
      </Section>

      {/* Product */}
      <Section title="Product">
        <CardList
          items={[
            { label: "Category", value: p.product?.category },
            { label: "Model", value: p.product?.model },
            { label: "Batch / Lot", value: p.product?.batchOrLot },
            { label: "Serial Number", value: p.product?.serialNumber },
            { label: "GTIN", value: p.product?.gtin },
            { label: "Description", value: p.product?.description },
          ]}
        />
      </Section>

      {/* Provenance */}
      <Section title="Provenance">
        <CardList
          items={[
            { label: "Economic Operator (LEI)", value: p.provenance?.operatorId },
            { label: "Facility (GLN)", value: p.provenance?.facilityId },
            { label: "Country of Origin", value: p.provenance?.countryOfOrigin },
            { label: "Manufacture Date", value: fmtDate(p.provenance?.manufactureDate) },
          ]}
        />
      </Section>

      {/* Documents */}
      <Section title="Documents">
        {p.documents?.length ? (
          <table className="ey-table">
            <thead>
              <tr><th>Type</th><th>URL</th><th>MIME</th><th>Hash</th></tr>
            </thead>
            <tbody>
              {p.documents.map((d, i) => (
                <tr key={i}>
                  <td>{d.type}</td>
                  <td><a className="ey-chip" href={d.url} target="_blank">{d.url}</a></td>
                  <td>{d.mime ?? "—"}</td>
                  <td>{d.hash ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p className="text-sm text-neutral-500">No documents provided.</p>
        )}
      </Section>

      {/* Compliance */}
      <Section title="Compliance">
        {p.compliance?.length ? (
          <table className="ey-table">
            <thead>
              <tr><th>Scheme</th><th>Reference</th><th>Valid From</th><th>Valid To</th></tr>
            </thead>
            <tbody>
              {p.compliance.map((c, i) => (
                <tr key={i}>
                  <td><Pill tone="blue">{c.scheme}</Pill></td>
                  <td>{c.reference}</td>
                  <td>{fmtDate(c.validFrom)}</td>
                  <td>{fmtDate(c.validTo)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p className="text-sm text-neutral-500">No compliance entries.</p>
        )}
      </Section>

      {/* Raw JSON */}
      <details className="ey-card p-4">
        <summary className="cursor-pointer font-medium">Show raw payload</summary>
        <pre className="mt-3 text-xs">{JSON.stringify(p, null, 2)}</pre>
      </details>
    </div>
  );
}
