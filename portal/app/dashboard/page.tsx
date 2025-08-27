// app/dashboard/page.tsx

import type { ReactNode } from "react";

type Metric = { value: string; label: string };
type Stakeholder = {
  title: string;
  role: string;
  interactions: string[];
  metrics?: Metric[];
};

function Section({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: ReactNode;
}) {
  return (
    <section className="ey-card ey-section p-5">
      <div className="mb-4">
        <h2 className="ey-stripe text-xl font-semibold">{title}</h2>
        {subtitle ? <p className="text-sm text-neutral-600 mt-1">{subtitle}</p> : null}
      </div>
      {children}
    </section>
  );
}

function StakeholderCard({ s }: { s: Stakeholder }) {
  return (
    <div className="ey-card p-4">
      <div className="text-lg font-semibold">{s.title}</div>
      <div className="text-sm text-purple-700 font-medium mt-0.5">{s.role}</div>

      <ul className="mt-3 space-y-2">
        {s.interactions.map((it, i) => (
          <li key={i} className="flex items-start gap-2">
            <span className="mt-1 inline-block h-2 w-2 rounded-full bg-emerald-500" />
            <span className="text-sm text-neutral-800">{it}</span>
          </li>
        ))}
      </ul>

      {s.metrics?.length ? (
        <div className="grid gap-2 mt-3 sm:grid-cols-2 md:grid-cols-3">
          {s.metrics.map((m, i) => (
            <div key={i} className="ey-metric">
              <div className="ey-metric__value">{m.value}</div>
              <div className="ey-metric__label">{m.label}</div>
            </div>
          ))}
        </div>
      ) : null}
    </div>
  );
}


export default function Dashboard() {
  const stakeholdersA: Stakeholder[] = [
    {
      title: "Supply Chain Operations",
      role: "Data Creators & Validators",
      interactions: [
        "Product registration & batch tracking",
        "Provenance data capture",
        "Quality assurance validation",
        "Handoff documentation",
      ],
      metrics: [
        { value: "23%", label: "Error Reduction" },
        { value: "18hrs", label: "Time Saved/Week" },
      ],
    },
    {
      title: "Compliance & Quality",
      role: "Regulatory Guardians",
      interactions: [
        "Automated compliance checking",
        "Audit trail generation",
        "Certification validation",
        "Regulatory reporting",
      ],
      metrics: [
        { value: "67%", label: "Audit Efficiency" },
        { value: "€180K", label: "Fine Avoidance" },
      ],
    },
    {
      title: "Customer Experience",
      role: "Trust & Transparency Seekers",
      interactions: [
        "Product authenticity verification",
        "Sustainability metrics access",
        "Usage & care instructions",
        "End-of-life guidance",
      ],
      metrics: [
        { value: "31%", label: "Trust Increase" },
        { value: "4.7/5", label: "Satisfaction" },
      ],
    },
    {
      title: "Executive Leadership",
      role: "Strategic Decision Makers",
      interactions: [
        "Risk mitigation insights",
        "Market differentiation data",
        "Operational efficiency metrics",
        "Investment ROI tracking",
      ],
      metrics: [
        { value: "15%", label: "Revenue Growth" },
        { value: "€2.3M", label: "Cost Savings" },
      ],
    },
  ];

  const stakeholdersB: Stakeholder[] = [
    {
      title: "Data Quality Loop",
      role: "Operations ↔ Compliance",
      interactions: [
        "Real-time validation feedback",
        "Predictive compliance alerts",
        "Automated correction suggestions",
      ],
      metrics: [{ value: "87%", label: "Data Accuracy" }],
    },
    {
      title: "Trust Amplification",
      role: "Compliance ↔ Customers",
      interactions: [
        "Verified sustainability claims",
        "Third-party certification display",
        "Transparent supply chain visibility",
      ],
      metrics: [{ value: "42%", label: "Brand Loyalty" }],
    },
    {
      title: "Strategic Intelligence",
      role: "Operations ↔ Leadership",
      interactions: [
        "Performance benchmarking",
        "Risk exposure mapping",
        "Market opportunity identification",
      ],
      metrics: [{ value: "28%", label: "Decision Speed" }],
    },
    {
      title: "Customer Intelligence",
      role: "Customers ↔ Leadership",
      interactions: [
        "Usage pattern analytics",
        "Sustainability preference insights",
        "Product improvement feedback",
      ],
      metrics: [{ value: "34%", label: "Innovation Rate" }],
    },
  ];

  const flow = [
    { n: "1", t: "Manufacturing", d: "Product creation with DPP ID, provenance and quality metrics" },
    { n: "2", t: "Distribution", d: "Custody tracking, location updates, condition monitoring" },
    { n: "3", t: "Retail/Sale", d: "Authenticity verification and product information disclosure" },
    { n: "4", t: "Usage", d: "Care instructions, warranty claims, performance feedback" },
    { n: "5", t: "End-of-Life", d: "Recycling guidance and material recovery data" },
  ] as const;

  const roi = [
    {
      title: "Cost Reduction",
      items: [
        ["Manual data entry elimination", "€340K/year"],
        ["Audit preparation time", "75% reduction"],
        ["Regulatory non-compliance fines", "€180K avoided"],
        ["Product recall efficiency", "89% faster"],
        ["Documentation management", "€120K/year"],
      ],
      toneClass: "text-amber-700",
    },
    {
      title: "Revenue Enhancement",
      items: [
        ["Premium pricing capability", "8–12%"],
        ["Market access (EU regulations)", "€890K opportunity"],
        ["Customer retention improvement", "23% increase"],
        ["B2B partnership acceleration", "31% faster"],
        ["Insurance premium reduction", "15–18%"],
      ],
      toneClass: "text-green-700",
    },
    {
      title: "Risk Mitigation",
      items: [
        ["Supply chain transparency", "98% visibility"],
        ["Counterfeiting prevention", "€2.1M protection"],
        ["Regulatory compliance assurance", "99.7% accuracy"],
        ["Reputation damage prevention", "—"],
        ["Data breach exposure", "67% reduction"],
      ],
      toneClass: "text-indigo-700",
    },
    {
      title: "Strategic Advantages",
      items: [
        ["Market differentiation", "First-mover"],
        ["Sustainability leadership", "ESG scoring"],
        ["Customer trust enhancement", "42% increase"],
        ["Operational excellence", "Continuous"],
        ["Digital transformation", "Future-ready"],
      ],
      toneClass: "text-purple-700",
    },
  ] as const;

  const compliance = [
    ["EU Digital Product Passport Regulation", "Mandatory scope for multiple product groups; schema keeps you future-ready.", "€890K Market Access"],
    ["Corporate Sustainability Reporting (CSRD)", "Automated ESG collection with integrated supply-chain transparency.", "75% Reporting Efficiency"],
    ["Supply Chain Due Diligence Acts", "Provenance tracking for German/EU supply chain responsibility.", "€180K Fine Avoidance"],
    ["Anti-Counterfeiting & Brand Protection", "Cryptographic authentication + immutable audit trails.", "€2.1M Revenue Protection"],
    ["Circular Economy Action Plan", "Composition & recycling guidance enable circularity.", "12% Premium Pricing"],
    ["GDPR & Data Privacy", "Privacy-by-design with selective disclosure & consent.", "€4M+ Fine Prevention"],
  ] as const;

  return (
    <main className="ey-container py-8 space-y-8">
      {/* Header */}
      <header className="text-center space-y-2">
        <h1 className="text-3xl font-bold">DPP Business Process Analysis</h1>
        <p className="text-neutral-600">
          Stakeholder Interactions, Value Propositions & ROI Framework
        </p>
      </header>

      {/* Two-column dashboard */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Section title="Key Stakeholder Ecosystem" subtitle="Primary actors in the DPP value chain">
          <div className="grid gap-4 sm:grid-cols-2">
            {stakeholdersA.map((s, i) => (
              <StakeholderCard key={i} s={s} />
            ))}
          </div>
        </Section>

        <Section title="Value Interaction Matrix" subtitle="Cross-stakeholder benefit flows">
          <div className="grid gap-4 sm:grid-cols-2">
            {stakeholdersB.map((s, i) => (
              <StakeholderCard key={i} s={s} />
            ))}
          </div>
        </Section>
      </div>

      {/* Flow diagram */}
      <Section title="DPP Data Flow Through Supply Chain" subtitle="End-to-end stakeholder interaction journey">
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
          {flow.map((s, i) => (
            <div key={i} className="ey-card p-4 text-center">
              <div className="mx-auto mb-2 flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-br from-indigo-600 to-purple-600 text-white text-xl font-bold shadow">
                {s.n}
              </div>
              <div className="font-semibold">{s.t}</div>
              <div className="text-sm text-neutral-600 mt-1">{s.d}</div>
            </div>
          ))}
        </div>
      </Section>

      {/* ROI & Value */}
      <Section title="ROI & Value Proposition Framework" subtitle="Quantified business impact across stakeholder groups">
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          {roi.map((cat, i) => (
            <div key={i} className="ey-card p-4">
              <div className={`flex items-center gap-2 font-semibold ${cat.toneClass}`}>
                <span className="h-3 w-3 rounded-full bg-current" />
                <h3>{cat.title}</h3>
              </div>
              <ul className="mt-2 divide-y">
                {cat.items.map(([benefit, impact], j) => (
                  <li key={j} className="py-2 text-sm flex items-center justify-between gap-3">
                    <span className="text-neutral-800">{benefit}</span>
                    <span className="ey-pill">{impact}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </Section>

      {/* Compliance value */}
      <Section title="Compliance Value Propositions" subtitle="Regulatory alignment and business value creation">
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {compliance.map(([title, desc, value], i) => (
            <div key={i} className="ey-card p-4">
              <div className="font-semibold">{title}</div>
              <div className="text-sm text-neutral-600 mt-1">{desc}</div>
              <span className="ey-pill ey-pill--yellow mt-3 inline-block">{value}</span>
            </div>
          ))}
        </div>
      </Section>

      <footer className="text-xs text-neutral-500 pt-2">
        Rendered at {new Date().toISOString()}
      </footer>
    </main>
  );
}
