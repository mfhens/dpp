# DPP Platform Documentation

Welcome to the Digital Product Passport (DPP) Platform documentation.

## Documentation Index

### Getting Started

- **[../Readme.md](../Readme.md)** - Quick start guide and project overview
- **[Architecture](./architecture.md)** - System architecture and component diagrams (C1, C2, C3)
- **[Data Model](./data-model.md)** - Database schema, versioning, and query patterns

### Reference Documentation

- **API Reference** - REST API endpoints and usage (coming soon)
- **Security Guide** - Authentication, authorization, and policy configuration (coming soon)
- **Deployment Guide** - Docker, Azure, and local deployment instructions (coming soon)

### Development Guides

- **Policy Authoring** - Writing OPA policies for field-level access control (coming soon)
- **Schema Management** - JSON Schema versioning and validation (coming soon)
- **Testing Guide** - Unit tests, integration tests, and policy tests (coming soon)

---

## Quick Links

### Architecture Diagrams

All diagrams follow the [C4 Model](https://c4model.com/) methodology using Mermaid syntax:

- **C1: System Context** - External systems and user interactions
- **C2: Container Architecture** - Core services, data stores, and integrations
- **C3: Component Architecture** - Internal API components and data flow

See [Architecture](./architecture.md) for complete diagrams.

### Key Concepts

#### Digital Product Passport (DPP)

A structured digital record containing product information, provenance, materials, and lifecycle events. Each DPP:

- Has a unique canonical identifier (`dpp_id`)
- Contains versioned JSON-LD payload data
- Supports time-travel queries
- Enforces field-level access control
- Maintains immutable audit history

#### Versioning

All DPP changes are append-only:

- Version 1 created on initial `POST /dpp`
- Subsequent versions via `POST /dpp/{id}/versions`
- Previous versions never modified or deleted
- Query any version by timestamp

#### Field-Level Masking

Access control at the field level using Open Policy Agent (OPA):

- Public tier: Basic product information
- Partner tier: Extended supply chain data
- Internal tier: Full data including sensitive fields
- Policies defined in Rego language

---

## Documentation Standards

When updating documentation:

1. **Update First, Create Second** - Check existing docs before creating new files
2. **Use Mermaid for Diagrams** - All diagrams in Mermaid syntax for GitHub rendering
3. **C4 Methodology** - Architecture diagrams follow C4 model (Context, Container, Component, Code)
4. **Relative Links** - Use relative links to other docs and code files
5. **Task Completion** - Development tasks include documentation updates

See [../agents.md](../agents.md) for complete documentation guidelines.

---

## Contributing

### Documentation Structure

```
docs/
├── README.md                  # This file - documentation index
├── architecture.md            # System architecture and C4 diagrams
├── data-model.md             # Database schema and versioning
├── api-reference.md          # REST API endpoints (coming soon)
├── security.md               # Auth/AuthZ configuration (coming soon)
├── deployment.md             # Deployment guides (coming soon)
└── policy.md                 # OPA policy authoring (coming soon)
```

### Mermaid Diagram Examples

All diagrams use Mermaid syntax. Common diagram types:

**Flowchart** (for C4 Container/Component):
```markdown
\`\`\`mermaid
flowchart TB
    A[Component A] --> B[Component B]
    B --> C[Component C]
\`\`\`
```

**Sequence Diagram** (for data flow):
```markdown
\`\`\`mermaid
sequenceDiagram
    Client->>API: Request
    API->>DB: Query
    DB-->>API: Data
    API-->>Client: Response
\`\`\`
```

**Entity Relationship** (for data model):
```markdown
\`\`\`mermaid
erDiagram
    DPP ||--o{ DPP_VERSION : "has versions"
\`\`\`
```

---

## Version History

- **v0.2.0** (Current) - Production deployment with field-level authorization
- **v0.1.0** - Initial PoC with basic CRUD operations

---

## Support

For questions or issues:

1. Check existing documentation
2. Review [../Readme.md](../Readme.md) for common scenarios
3. Contact maintainers listed in main README

---

## License

See root LICENSE file for license information.
