export const dynamic = "force-dynamic";

import type { ReactNode } from "react";

type PillTone = "default" | "green" | "amber" | "blue";
type ApiDpp = { dpp_id: string; version: number; payload: unknown };

// --- Fetcher ---
async function getDpp(id: string, at?: string) {
  // Use API_BASE from environment, fallback to Azure deployment URL
  const base = process.env.API_BASE || "https://dpp-brickquack-api.azurewebsites.net";
  const u = new URL(`${base}/dpp/${id}`);
  if (at) u.searchParams.set("at", at);
  const res = await fetch(u.toString(), { headers: { "x-access-tier": "public" }, cache: "no-store" });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`API error ${res.status}`);
  return (await res.json()) as ApiDpp;
}

// --- Payload types ---
type ProductIdentifier = { type: string; value: string };
type Material = { name: string; type: string; percentage: number; origin?: string; certifications?: string[]; recyclingProcess?: string };
type RecyclableMaterial = { material: string; percentage: number; recyclingProcess?: string };
type SubstanceOfConcern = { name: string; casNumber?: string; concentration?: number; unit?: string; regulatoryList?: string; location?: string };
type SupplierId = { id: string; name?: string; type?: string; legalEntityIdentifier?: string };
type FacilityId = { id: string; type?: string; location?: string };

type DppPayload = {
  id?: string;
  schemaVersion?: string;
  dppUrl?: string;
  registryId?: string;
  createdAt?: string;
  updatedAt?: string;
  product?: { 
    category?: string; 
    model?: string; 
    batchOrLot?: string; 
    serialNumber?: string; 
    gtin?: string; 
    description?: string;
    identifiers?: {
      productIds?: ProductIdentifier[];
      materials?: Material[];
    };
  };
  provenance?: { 
    operatorId?: string; 
    facilityId?: string; 
    facilityIds?: FacilityId[];
    supplierIds?: SupplierId[];
    countryOfOrigin?: string; 
    manufactureDate?: string;
  };
  compliance?: Array<{ scheme: string; reference: string; validFrom?: string; validTo?: string }>;
  documents?: Array<{ type: string; url: string; hash?: string; mime?: string }>;
  substancesOfConcern?: SubstanceOfConcern[];
  environmentalFootprint?: {
    productCarbonFootprint?: {
      value?: number;
      unit?: string;
      scope?: string;
      calculationMethod?: string;
      dataQuality?: string;
    };
    externalLink?: string;
    waterFootprint?: number;
    energyConsumption?: number;
  };
  circularity?: {
    recyclabilityScore?: number;
    recyclabilityInformation?: {
      recyclableMaterials?: RecyclableMaterial[];
      disposalGuidelines?: string;
      eolInstructions?: string;
    };
    recycledContent?: number;
    repairability?: {
      score?: number;
      assessmentMethod?: string;
      spareParts?: {
        availability?: string;
        period?: string;
      };
    };
    designForDisassembly?: boolean;
    circulatoryPotential?: string;
  };
  planningInsights?: Record<string, unknown>;
  transportOptimization?: {
    maintenanceSchedule?: string;
    locations?: Array<{
      locationFrom: string;
      locationId: string;
      adjustedTransportQuantity: number;
      standardTransportQuantity: number;
      previousTransportFootprint: number;
      currentTransportFootprint: number;
      quantitySavings?: string;
      footprintChange?: string;
    }>;
  };
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

      {/* Product Identifiers */}
      {p.product?.identifiers?.productIds && p.product.identifiers.productIds.length > 0 && (
        <Section title="Product Identifiers">
          <table className="ey-table">
            <thead>
              <tr><th>Type</th><th>Value</th></tr>
            </thead>
            <tbody>
              {p.product.identifiers.productIds.map((pid, i) => (
                <tr key={`pid-${i}`}>
                  <td><Pill tone="blue">{pid.type}</Pill></td>
                  <td>{pid.value}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Section>
      )}

      {/* Materials Composition */}
      {p.product?.identifiers?.materials && p.product.identifiers.materials.length > 0 && (
        <Section title="Materials & Composition">
          <table className="ey-table">
            <thead>
              <tr><th>Material Name</th><th>Type</th><th>Percentage</th><th>Origin</th><th>Certifications</th></tr>
            </thead>
            <tbody>
              {p.product.identifiers.materials.map((mat, i) => {
                // Try to find matching DPP in BOM
                let dppLink: string | null = null;
                const bomProfile = p.profiles?.["component.bom"] || p.profiles?.["product.bom"];
                const components = bomProfile?.components as Array<{
                  material: string;
                  dpp?: string;
                }> | undefined;
                
                if (components) {
                  // Normalize material name for matching (remove spaces, hyphens, parentheses)
                  const normalizeForMatching = (name: string) => 
                    name.toLowerCase().replace(/[\s\-\(\)]/g, '');
                  
                  const materialNameNormalized = normalizeForMatching(mat.name);
                  const matchedComponent = components.find(comp => {
                    const compNameNormalized = normalizeForMatching(comp.material);
                    
                    // Direct match after normalization
                    if (materialNameNormalized.includes(compNameNormalized) || 
                        compNameNormalized.includes(materialNameNormalized)) {
                      return true;
                    }
                    
                    // Additional fuzzy matching for common patterns
                    const materialNameLower = mat.name.toLowerCase();
                    const compNameLower = comp.material.toLowerCase();
                    return (materialNameLower.includes('abs') && compNameLower.includes('abs')) ||
                           (materialNameLower.includes('carbon') && compNameLower.includes('cb')) ||
                           (materialNameLower.includes('pvc') && compNameLower.includes('pvc')) ||
                           (materialNameLower.includes('paper') && compNameLower.includes('pb'));
                  });
                  
                  if (matchedComponent?.dpp) {
                    dppLink = `/dpp/${encodeURIComponent(matchedComponent.dpp)}`;
                  }
                }

                return (
                  <tr key={`mat-${i}`}>
                    <td>
                      {dppLink ? (
                        <a href={dppLink} className="text-blue-600 hover:text-blue-800 hover:underline font-medium inline-flex items-center gap-1">
                          {mat.name} 🔗
                        </a>
                      ) : (
                        mat.name
                      )}
                    </td>
                    <td><Pill>{mat.type}</Pill></td>
                    <td>{mat.percentage}%</td>
                    <td>{mat.origin ?? "—"}</td>
                    <td>{mat.certifications?.join(", ") ?? "—"}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          <p className="text-xs text-neutral-500 mt-2">💡 Click on linked materials to view their detailed DPPs</p>
        </Section>
      )}

      {/* Bill of Materials */}
      {p.profiles?.["component.bom"]?.components || p.profiles?.["product.bom"]?.components ? (
        <Section title="Bill of Materials (BOM)">
          {(() => {
            const bomProfile = p.profiles["component.bom"] || p.profiles["product.bom"];
            const components = bomProfile?.components as Array<{
              material: string;
              quantity: number;
              unit: string;
              dpp?: string;
            }> | undefined;

            if (!components || components.length === 0) return null;

            return (
              <div className="space-y-2">
                <p className="text-sm text-neutral-600 mb-3">
                  This product is composed of the following components. Click on a component to view its detailed DPP.
                </p>
                <table className="ey-table">
                  <thead>
                    <tr><th>Component</th><th>Quantity</th><th>Unit</th><th>DPP Reference</th></tr>
                  </thead>
                  <tbody>
                    {components.map((comp, i) => {
                      // Extract the DPP ID from the full DID
                      const dppId = comp.dpp;
                      const dppLink = dppId ? `/dpp/${encodeURIComponent(dppId)}` : null;
                      
                      return (
                        <tr key={`comp-${i}`}>
                          <td>
                            <Pill tone="amber">{comp.material}</Pill>
                          </td>
                          <td className="font-medium">{comp.quantity}</td>
                          <td>{comp.unit}</td>
                          <td>
                            {dppLink ? (
                              <a 
                                href={dppLink} 
                                className="text-blue-600 hover:text-blue-800 hover:underline font-medium flex items-center gap-1"
                                title={`View DPP for ${comp.material}`}
                              >
                                View DPP 🔗
                              </a>
                            ) : (
                              <span className="text-neutral-400">—</span>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            );
          })()}
        </Section>
      ) : null}

      {/* Provenance */}
      <Section title="Provenance">
        <CardList
          items={[
            { label: "Economic Operator (LEI)", value: p.provenance?.operatorId },
            { label: "Primary Facility (GLN)", value: p.provenance?.facilityId },
            { label: "Country of Origin", value: p.provenance?.countryOfOrigin },
            { label: "Manufacture Date", value: fmtDate(p.provenance?.manufactureDate) },
          ]}
        />
      </Section>

      {/* Facility Information */}
      {p.provenance?.facilityIds && p.provenance.facilityIds.length > 0 && (
        <Section title="Facility Information">
          <table className="ey-table">
            <thead>
              <tr><th>Facility ID</th><th>Type</th><th>Location</th></tr>
            </thead>
            <tbody>
              {p.provenance.facilityIds.map((fac, i) => (
                <tr key={`fac-${i}`}>
                  <td><code className="ey-chip">{fac.id}</code></td>
                  <td><Pill tone="amber">{fac.type ?? "—"}</Pill></td>
                  <td>{fac.location ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Section>
      )}

      {/* Supplier Information */}
      {p.provenance?.supplierIds && p.provenance.supplierIds.length > 0 && (
        <Section title="Supplier Information">
          <table className="ey-table">
            <thead>
              <tr><th>Supplier ID</th><th>Name</th><th>Type</th><th>Legal Entity Identifier</th></tr>
            </thead>
            <tbody>
              {p.provenance.supplierIds.map((sup, i) => (
                <tr key={`sup-${i}`}>
                  <td><code className="ey-chip">{sup.id}</code></td>
                  <td>{sup.name ?? "—"}</td>
                  <td><Pill>{sup.type ?? "—"}</Pill></td>
                  <td>{sup.legalEntityIdentifier ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Section>
      )}

      {/* Substances of Concern */}
      {p.substancesOfConcern && p.substancesOfConcern.length > 0 && (
        <Section title="Substances of Concern">
          <table className="ey-table">
            <thead>
              <tr><th>Substance</th><th>CAS Number</th><th>Concentration</th><th>Regulatory List</th><th>Location</th></tr>
            </thead>
            <tbody>
              {p.substancesOfConcern.map((sub, i) => (
                <tr key={`sub-${i}`}>
                  <td>{sub.name}</td>
                  <td>{sub.casNumber ?? "—"}</td>
                  <td>{sub.concentration !== undefined ? `${sub.concentration} ${sub.unit ?? ""}` : "—"}</td>
                  <td><Pill tone="amber">{sub.regulatoryList ?? "—"}</Pill></td>
                  <td>{sub.location ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Section>
      )}
      {!p.substancesOfConcern || p.substancesOfConcern.length === 0 && (
        <Section title="Substances of Concern">
          <p className="text-sm text-emerald-600">✓ No substances of concern identified</p>
        </Section>
      )}

      {/* Environmental Footprint */}
      <Section title="Environmental Footprint">
        {p.environmentalFootprint?.productCarbonFootprint ? (
          <div className="space-y-4">
            {/* Lifecycle Carbon Footprint Summary (if transport data available) */}
            {(() => {
              const transportCF = p.planningInsights?.transportCarbonFootprint as { current?: number; unit?: string } | undefined;
              const productPCF = p.environmentalFootprint.productCarbonFootprint.value || 0;
              const transportCurrent = transportCF?.current || 0;
              
              if (transportCurrent > 0) {
                const total = productPCF + transportCurrent;
                return (
                  <div className="ey-card p-4 bg-purple-50 border-2 border-purple-200">
                    <h3 className="font-semibold mb-3 text-purple-900">Lifecycle Carbon Footprint</h3>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-3">
                      <div>
                        <p className="text-xs text-purple-700 uppercase tracking-wide">Manufacturing</p>
                        <p className="text-2xl font-bold text-purple-900">{productPCF}</p>
                        <p className="text-xs text-purple-600">{p.environmentalFootprint.productCarbonFootprint.unit || 'kg CO2e'}</p>
                      </div>
                      <div>
                        <p className="text-xs text-purple-700 uppercase tracking-wide">Transport</p>
                        <p className="text-2xl font-bold text-purple-900">{transportCurrent}</p>
                        <p className="text-xs text-purple-600">{transportCF?.unit || 'kg CO2e'}</p>
                      </div>
                      <div className="border-l-2 border-purple-300 pl-4">
                        <p className="text-xs text-purple-700 uppercase tracking-wide">Total Lifecycle</p>
                        <p className="text-3xl font-bold text-purple-900">{total.toFixed(2)}</p>
                        <p className="text-xs text-purple-600">{p.environmentalFootprint.productCarbonFootprint.unit || 'kg CO2e'}</p>
                      </div>
                    </div>
                    <p className="text-xs text-purple-700">
                      This includes manufacturing ({Math.round((productPCF/total)*100)}%) and distribution transport ({Math.round((transportCurrent/total)*100)}%) emissions.
                    </p>
                  </div>
                );
              }
              return null;
            })()}
            
            <div className="ey-card p-4 bg-blue-50">
              <h3 className="font-semibold mb-2">Product Carbon Footprint (PCF)</h3>
              <CardList
                items={[
                  { label: "Value", value: `${p.environmentalFootprint.productCarbonFootprint.value} ${p.environmentalFootprint.productCarbonFootprint.unit ?? ""}` },
                  { label: "Scope", value: p.environmentalFootprint.productCarbonFootprint.scope },
                  { label: "Calculation Method", value: p.environmentalFootprint.productCarbonFootprint.calculationMethod },
                  { label: "Data Quality", value: p.environmentalFootprint.productCarbonFootprint.dataQuality },
                ]}
              />
            </div>
            <CardList
              items={[
                { label: "Water Footprint", value: p.environmentalFootprint.waterFootprint ? `${p.environmentalFootprint.waterFootprint} liters` : undefined },
                { label: "Energy Consumption", value: p.environmentalFootprint.energyConsumption ? `${p.environmentalFootprint.energyConsumption} kWh` : undefined },
                { 
                  label: "Detailed Report", 
                  value: p.environmentalFootprint.externalLink ? (
                    <a className="ey-chip hover:underline" href={p.environmentalFootprint.externalLink} target="_blank" rel="noopener noreferrer">View Report</a>
                  ) : undefined
                },
              ]}
            />
          </div>
        ) : (
          <p className="text-sm text-neutral-500">No environmental footprint data available.</p>
        )}
      </Section>

      {/* Circularity & Recyclability */}
      <Section title="Circularity & Recyclability Information">
        {p.circularity ? (
          <div className="space-y-4">
            <CardList
              items={[
                { label: "Recyclability Score", value: p.circularity.recyclabilityScore !== undefined ? `${p.circularity.recyclabilityScore}%` : undefined },
                { label: "Recycled Content", value: p.circularity.recycledContent !== undefined ? `${p.circularity.recycledContent}%` : undefined },
                { label: "Design for Disassembly", value: p.circularity.designForDisassembly ? "Yes" : "No" },
                { label: "Circulatory Potential", value: p.circularity.circulatoryPotential },
              ]}
            />
            
            {p.circularity.recyclabilityInformation && (
              <>
                {p.circularity.recyclabilityInformation.recyclableMaterials && p.circularity.recyclabilityInformation.recyclableMaterials.length > 0 && (
                  <div>
                    <h3 className="font-semibold mb-2">Recyclable Materials</h3>
                    <table className="ey-table">
                      <thead>
                        <tr><th>Material</th><th>Percentage</th><th>Recycling Process</th></tr>
                      </thead>
                      <tbody>
                        {p.circularity.recyclabilityInformation.recyclableMaterials.map((rm, i) => (
                          <tr key={`rm-${i}`}>
                            <td>{rm.material}</td>
                            <td>{rm.percentage}%</td>
                            <td>{rm.recyclingProcess ?? "—"}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
                
                {p.circularity.recyclabilityInformation.disposalGuidelines && (
                  <div className="ey-card p-4 bg-green-50">
                    <h3 className="font-semibold mb-2">Disposal Guidelines</h3>
                    <p className="text-sm">{p.circularity.recyclabilityInformation.disposalGuidelines}</p>
                  </div>
                )}
                
                {p.circularity.recyclabilityInformation.eolInstructions && (
                  <div className="ey-card p-4 bg-green-50">
                    <h3 className="font-semibold mb-2">End-of-Life Instructions</h3>
                    <p className="text-sm">{p.circularity.recyclabilityInformation.eolInstructions}</p>
                  </div>
                )}
              </>
            )}

            {p.circularity.repairability && (
              <div className="ey-card p-4 bg-amber-50">
                <h3 className="font-semibold mb-2">Repairability</h3>
                <CardList
                  items={[
                    { label: "Score", value: p.circularity.repairability.score !== undefined ? `${p.circularity.repairability.score}/10` : undefined },
                    { label: "Assessment Method", value: p.circularity.repairability.assessmentMethod },
                    { label: "Spare Parts Availability", value: p.circularity.repairability.spareParts?.availability },
                    { label: "Spare Parts Period", value: p.circularity.repairability.spareParts?.period },
                  ]}
                />
              </div>
            )}
          </div>
        ) : (
          <p className="text-sm text-neutral-500">No circularity information available.</p>
        )}
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
                <tr key={`doc-${i}`}>
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
      <Section title="Compliance Documentation">
        {p.compliance?.length ? (
          <table className="ey-table">
            <thead>
              <tr><th>Scheme</th><th>Reference</th><th>Valid From</th><th>Valid To</th></tr>
            </thead>
            <tbody>
              {p.compliance.map((c, i) => (
                <tr key={`comp-${i}`}>
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

      {/* Transport Optimization */}
      {(() => {
        // Extract locations from planningInsights (as created by update_planning_insights.py)
        const planningLocations = p.planningInsights?.locations;
        const locations = p.transportOptimization?.locations || 
          (planningLocations && Array.isArray(planningLocations) 
            ? planningLocations as Array<{
                locationFrom: string;
                locationId: string;
                adjustedTransportQuantity: number;
                standardTransportQuantity: number;
                previousTransportFootprint: number;
                currentTransportFootprint: number;
                quantitySavings?: string;
                footprintChange?: string;
              }>
            : null);
        
        const maintenanceSchedule = p.transportOptimization?.maintenanceSchedule || 
          (typeof p.planningInsights?.maintenanceSchedule === 'string' ? p.planningInsights.maintenanceSchedule : null);

        if (!locations || locations.length === 0) return null;

        // Extract transport carbon footprint data from planningInsights
        const transportCarbonFootprint = p.planningInsights?.transportCarbonFootprint as {
          current?: number;
          previous?: number;
          unit?: string;
          scope?: string;
          change?: number;
          changeAbsolute?: number;
        } | undefined;

        return (
          <Section title="Transport Optimization">
            {/* Current Carbon Footprint */}
            {transportCarbonFootprint && (
              <div className="ey-card p-4 bg-neutral-50 mb-4">
                <h3 className="font-semibold mb-2">Transport Carbon Footprint</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-neutral-600">Current</p>
                    <p className="text-xl font-semibold text-neutral-900">
                      {transportCarbonFootprint.current} {transportCarbonFootprint.unit || 'kg CO2e'}
                    </p>
                    <p className="text-xs text-neutral-500">Scope: {transportCarbonFootprint.scope || 'transport-distribution'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-neutral-600">Previous</p>
                    <p className="text-xl font-semibold text-neutral-900">
                      {transportCarbonFootprint.previous} {transportCarbonFootprint.unit || 'kg CO2e'}
                    </p>
                    {transportCarbonFootprint.change !== undefined && (
                      <p className={`text-sm font-medium ${transportCarbonFootprint.change < 0 ? 'text-green-700' : 'text-red-700'}`}>
                        {transportCarbonFootprint.change > 0 ? '+' : ''}{transportCarbonFootprint.change}% 
                        ({transportCarbonFootprint.changeAbsolute !== undefined && transportCarbonFootprint.changeAbsolute > 0 ? '+' : ''}{transportCarbonFootprint.changeAbsolute} {transportCarbonFootprint.unit || 'kg CO2e'})
                      </p>
                    )}
                  </div>
                </div>
              </div>
            )}
            
            {/* Planner Suggestions Header */}
            <div className="ey-card p-4 bg-blue-50 mb-4">
              <p className="text-base text-blue-900">
                Our planner suggests the following changes to align with Brickquack's sustainability planning strategy:
              </p>
            </div>
            
            <div className="overflow-x-auto">
              <table className="ey-table">
                <thead>
                  <tr>
                    <th>Location From</th>
                    <th>Location ID</th>
                    <th>Adjusted Transport Quantity</th>
                    <th>Standard Transport Quantity</th>
                    <th>Previous Transport Footprint</th>
                    <th>Current Transport Footprint</th>
                    <th>Quantity Savings</th>
                    <th>Footprint Change</th>
                  </tr>
                </thead>
                <tbody>
                  {locations.map((loc, i) => {
                    const quantitySavingsValue = loc.quantitySavings || (
                      loc.standardTransportQuantity > 0 
                        ? `${(((loc.adjustedTransportQuantity - loc.standardTransportQuantity) / loc.standardTransportQuantity) * 100).toFixed(1)}%`
                        : '-'
                    );
                    const footprintChangeValue = loc.footprintChange || (
                      loc.previousTransportFootprint > 0
                        ? `${(((loc.currentTransportFootprint - loc.previousTransportFootprint) / loc.previousTransportFootprint) * 100).toFixed(1)}%`
                        : '-'
                    );
                    
                    // Determine cell colors based on positive/negative values
                    const quantitySavingsClass = quantitySavingsValue.startsWith('-') && quantitySavingsValue !== '-' 
                      ? 'text-green-700 font-semibold' 
                      : quantitySavingsValue !== '-' 
                      ? 'text-red-700 font-semibold' 
                      : '';
                    const footprintChangeClass = footprintChangeValue.startsWith('-') && footprintChangeValue !== '-'
                      ? 'text-green-700 font-semibold'
                      : footprintChangeValue !== '-' && !footprintChangeValue.startsWith('-')
                      ? 'text-red-700 font-semibold'
                      : '';

                    return (
                      <tr key={`loc-${i}`}>
                        <td><Pill tone="blue">{loc.locationFrom}</Pill></td>
                        <td>{loc.locationId}</td>
                        <td>{loc.adjustedTransportQuantity}</td>
                        <td>{loc.standardTransportQuantity}</td>
                        <td>{loc.previousTransportFootprint}</td>
                        <td>{loc.currentTransportFootprint}</td>
                        <td className={quantitySavingsClass}>{quantitySavingsValue}</td>
                        <td className={footprintChangeClass}>{footprintChangeValue}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            
            {/* Carbon Footprint Reduction Summary */}
            {transportCarbonFootprint && transportCarbonFootprint.changeAbsolute !== undefined && (
              <div className={`ey-card p-4 mt-4 ${transportCarbonFootprint.changeAbsolute < 0 ? 'bg-green-50' : 'bg-amber-50'}`}>
                <p className={`text-base font-medium ${transportCarbonFootprint.changeAbsolute < 0 ? 'text-green-900' : 'text-amber-900'}`}>
                  {transportCarbonFootprint.changeAbsolute < 0 
                    ? `✓ The transport carbon footprint has been reduced by ${Math.abs(transportCarbonFootprint.changeAbsolute)} ${transportCarbonFootprint.unit || 'kg CO2e'} (${Math.abs(transportCarbonFootprint.change || 0)}%) through optimized routing.`
                    : `⚠ The transport carbon footprint has increased by ${transportCarbonFootprint.changeAbsolute} ${transportCarbonFootprint.unit || 'kg CO2e'} (+${transportCarbonFootprint.change || 0}%) due to new routes or demand changes.`
                  }
                </p>
              </div>
            )}
          </Section>
        );
      })()}

      {/* Raw JSON */}
      <details className="ey-card p-4">
        <summary className="cursor-pointer font-medium">Show raw payload</summary>
        <pre className="mt-3 text-xs">{JSON.stringify(p, null, 2)}</pre>
      </details>
    </div>
  );
}
