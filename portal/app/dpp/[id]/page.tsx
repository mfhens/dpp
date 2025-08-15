export const dynamic = "force-dynamic";

type ApiDpp = { dpp_id: string; version: number; payload: unknown };

async function getDpp(id: string, at?: string) {
  const base = process.env.API_BASE || "http://localhost:8000";
  const u = new URL(`${base}/dpp/${id}`);
  if (at) u.searchParams.set("at", at);

  const res = await fetch(u.toString(), {
    headers: { "x-access-tier": "public" },
    cache: "no-store"
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`API error ${res.status}`);
  return (await res.json()) as ApiDpp;
}

export default async function Page({ params, searchParams }: { params: { id: string }, searchParams?: { at?: string } }) {
  const data = await getDpp(params.id, searchParams?.at);
  if (!data) return <div className="p-4">DPP not found</div>;

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-semibold">Digital Product Passport</h1>
        <p className="text-sm opacity-80">ID: {data.dpp_id} • v{data.version}</p>
      </div>

      <div className="rounded-xl border border-white/10 bg-white/5 p-4">
        <div className="text-sm opacity-80 mb-2">Payload</div>
        <pre className="text-sm overflow-auto">{JSON.stringify(data.payload, null, 2)}</pre>
      </div>
    </div>
  );
}
