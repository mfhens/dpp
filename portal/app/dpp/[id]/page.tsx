export const dynamic = "force-dynamic";

type ApiDpp = { dpp_id: string; version: number; payload: unknown };

async function getDpp(id: string, at?: string) {
  const base = process.env.API_BASE || "http://localhost:8000";
  const u = new URL(`${base}/dpp/${id}`);
  if (at) u.searchParams.set("at", at);

  console.log(`[DEBUG] Fetching DPP: url=${u.toString()} id=${id} at=${at}`);

  try {
    const res = await fetch(u.toString(), {
      headers: { "x-access-tier": "public" },
      cache: "no-store"
    });
    console.log(`[DEBUG] Response status: ${res.status}`);
    if (res.status === 404) {
      console.log(`[DEBUG] DPP not found for id=${id}`);
      return null;
    }
    if (!res.ok) {
      console.error(`[ERROR] API error ${res.status} for id=${id}`);
      throw new Error(`API error ${res.status}`);
    }
    const json = await res.json();
    console.log(`[DEBUG] DPP data received:`, json);
    return json as ApiDpp;
  } catch (err) {
    console.error(`[ERROR] Exception in getDpp for id=${id}:`, err);
    throw err;
  }
}

export default async function Page({ params, searchParams }: { params: { id: string }, searchParams?: { at?: string } }) {
  console.log(`[DEBUG] Page params:`, params, searchParams);
  const data = await getDpp(params.id, searchParams?.at);
  if (!data) {
    console.log(`[DEBUG] Rendering 'DPP not found' for id=${params.id}`);
    return <div className="p-4">DPP not found</div>;
  }

  console.log(`[DEBUG] Rendering DPP page for id=${data.dpp_id} version=${data.version}`);
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
