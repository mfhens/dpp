# DPP Platform Architecture

## Overview

The Digital Product Passport (DPP) Platform is a production-ready system for managing digital product passports with comprehensive authentication, authorization, and audit capabilities. The platform supports multiple deployment models (local development, Docker, Azure) and implements field-level data masking based on Open Policy Agent (OPA) policies.

## Table of Contents

- [Architecture Diagrams](#architecture-diagrams)
  - [C1: System Context](#c1-system-context)
  - [C2: Container Architecture](#c2-container-architecture)
  - [C3: API Components](#c3-api-components)
- [Current Implementation](#current-implementation)
- [Key Features](#key-features)
- [Deployment Models](#deployment-models)
- [Data Flow](#data-flow)

---

## Architecture Diagrams

### C1: System Context

```mermaid
flowchart TB
    subgraph External["External Systems"]
        User["👤 User<br/>(Engineer/QA/Public)"]
        IdP["🔐 Auth Server<br/>(Keycloak)<br/>OAuth2/OIDC"]
        Obs["📊 Observability<br/>(Logs/Traces/Metrics)"]
    end

    subgraph DPP["DPP Platform"]
        Portal["🌐 Public/Partner Portal<br/>(Next.js SPA)<br/>Web UI"]
        Mobile["📱 Field App<br/>(Mobile)<br/>Scan & Lifecycle"]
        API["⚙️ DPP API Gateway<br/>(FastAPI)<br/>REST/JSON"]
    end

    User -->|Browse & Manage| Portal
    User -->|Scan & Update| Mobile
    Portal -->|OIDC Login| IdP
    Mobile -->|OIDC Login| IdP
    Portal -->|API Calls + JWT| API
    Mobile -->|Sync Events| API
    API -->|Token Validation| IdP
    API -->|Metrics & Logs| Obs

    classDef external fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef system fill:#fff3e0,stroke:#e65100,stroke-width:3px
    classDef container fill:#f3e5f5,stroke:#4a148c,stroke-width:2px

    class External external
    class DPP system
    class User,IdP,Obs external
    class Portal,Mobile,API container
```

### C2: Container Architecture

```mermaid
flowchart TB
    subgraph External["External Systems"]
        IdP["🔐 Auth Server<br/>(Keycloak)<br/>Tokens & Federation"]
        Obs["📊 Observability<br/>(Application Insights)<br/>Monitoring"]
    end

    subgraph Platform["DPP Platform"]
        subgraph Core["Core Services"]
            API["⚙️ DPP API Gateway<br/>(FastAPI + Python)<br/>REST/JSON-LD Endpoints"]
            PDP["🛡️ Policy Decision Point<br/>(OPA + ABAC)<br/>Field-level Filtering"]
            UID["🔢 Identifier Management<br/>(Service)<br/>UID Generation/Validation"]
            Watcher["👁️ Planning Insights Watcher<br/>(Background Service)<br/>CSV Processing"]
        end

        subgraph UI["User Interfaces"]
            Portal["🌐 Public Portal<br/>(Next.js)<br/>Browse & Manage"]
        end

        subgraph Data["Data Stores"]
            DB["💾 DPP Store<br/>(PostgreSQL/SQLite)<br/>Passport Data + Versioning"]
            Audit["📝 Audit Log<br/>(Append-only)<br/>Tamper-evident History"]
            ObjStore["📦 Object Store<br/>(MinIO/Azure Blob)<br/>Attachments & Schemas"]
        end
    end

    Portal -->|Consume APIs| API
    API -->|AuthZ Decisions| PDP
    API -->|Resolve/Validate IDs| UID
    API -->|CRUD Passports| DB
    API -->|Append Events| Audit
    API -->|Store Attachments| ObjStore
    API -->|Token Validation| IdP
    API -->|Logs & Metrics| Obs
    Watcher -->|Update DPPs| DB
    Watcher -->|Audit Events| Audit

    classDef external fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef coreService fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
    classDef uiService fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef dataService fill:#fff9c4,stroke:#f57f17,stroke-width:2px

    class IdP,Obs external
    class API,PDP,UID,Watcher coreService
    class Portal uiService
    class DB,Audit,ObjStore dataService
```

### C3: API Components

```mermaid
flowchart TB
    subgraph API["DPP API Gateway"]
        subgraph Routes["API Routes"]
            PublicRead["📖 Public Read API<br/>GET /dpp/{id}<br/>GET /dpp/search"]
            Lifecycle["🔄 Lifecycle API<br/>POST /dpp<br/>POST /dpp/{id}/versions<br/>DELETE /dpp/{id}"]
            Upload["📤 Upload API<br/>POST /dpp/{id}/attachments<br/>POST /upload/planning-insights"]
            Health["❤️ Health Check<br/>GET /health"]
        end

        subgraph Auth["Authentication & Authorization"]
            JWT["🔐 JWT Middleware<br/>Token Validation<br/>JWKS Caching"]
            OPAFilter["🛡️ Access Filter<br/>OPA Policy Enforcement<br/>Field Masking"]
        end

        subgraph Services["Business Services"]
            Resolver["🔢 UID Resolver<br/>Normalize & Validate<br/>GS1 Digital Link"]
            Validator["✅ Schema Validator<br/>JSON Schema 2020-12<br/>Payload Validation"]
            Masking["🎭 Masking Engine<br/>Apply OPA Decisions<br/>Field Redaction"]
            AuditSvc["📝 Audit Service<br/>Append-only Logging<br/>Event Tracking"]
        end

        subgraph Data["Data Access"]
            Models["💾 ORM Models<br/>Dpp + DppVersion<br/>SQLAlchemy 2.x"]
            ObjClient["📦 Object Store Client<br/>MinIO/Azure Blob<br/>Attachment Management"]
        end
    end

    PublicRead --> JWT
    Lifecycle --> JWT
    Upload --> JWT
    JWT --> OPAFilter
    OPAFilter --> Resolver
    OPAFilter --> Validator
    OPAFilter --> Masking
    Resolver --> Models
    Validator --> Models
    Masking --> Models
    Models --> AuditSvc
    Upload --> ObjClient

    classDef route fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef auth fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef service fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
    classDef data fill:#f3e5f5,stroke:#4a148c,stroke-width:2px

    class PublicRead,Lifecycle,Upload,Health route
    class JWT,OPAFilter auth
    class Resolver,Validator,Masking,AuditSvc service
    class Models,ObjClient data
```

---

## Current Implementation

### Core Components

#### 1. **DPP API Gateway** (`api/dpp_api/`)

The primary backend service built with FastAPI:

- **Main Application** (`main.py`):
  - RESTful endpoints for DPP lifecycle management
  - Health checks and monitoring
  - Automatic schema validation
  - Comprehensive logging with file and console output
  - Background file watcher for planning insights

- **Authentication** (`auth.py`):
  - OIDC/OAuth2 integration with Keycloak
  - JWT validation with JWKS caching
  - Scope and role extraction from tokens
  - Anonymous access support for public reads
  - Demo mode for development (⚠️ disabled in production)

- **Authorization** (`auth.py`):
  - OPA integration for policy decisions
  - Field-level data masking based on policy
  - Access tier support (public/partner/internal)
  - Fail-closed security model

- **Data Models** (`models.py`):
  - `Dpp`: Header/metadata for each product passport
  - `DppVersion`: Append-only version history
  - PostgreSQL (production) or SQLite (development)
  - SQLAlchemy 2.x ORM with proper type hints

- **Services**:
  - **Identifier Management** (`services/identifiers.py`): UID normalization and Digital Link generation
  - **Object Store** (`services/object_store.py`): MinIO/Azure Blob integration for attachments
  - **Audit** (`services/audit.py`): Append-only audit logging for compliance

- **Background Workers**:
  - **Planning Insights Watcher** (`planning_insights_watcher.py`): Monitors drop folder for CSV files and updates DPP records

#### 2. **Public Portal** (`portal/`)

Next.js-based web application:

- TypeScript/React frontend
- Server-side rendering (SSR) support
- Tailwind CSS styling
- Environment-based configuration
- Production deployment via Azure App Service or Docker

#### 3. **Policy Engine** (`opa/`)

Open Policy Agent for authorization:

- Rego policy bundle (`bundle.rego`)
- Field-level masking decisions
- ABAC (Attribute-Based Access Control)
- Policy data bundles (`data.json`)

#### 4. **Identity Provider** (`keycloak/`)

Keycloak configuration:

- OAuth2/OIDC provider
- Realm imports for seeded data
- Client configurations
- Role-based access control

### Key Features

#### Authentication & Authorization

- **Multi-tier Access**: Public, Partner, Internal access levels
- **Fine-grained Control**: Field-level data masking via OPA
- **Token Management**: JWT validation with automatic JWKS refresh
- **Role Mapping**: Keycloak realm and resource roles to scopes

#### Data Management

- **Versioning**: Append-only version history for all DPPs
- **Time Travel**: Query DPP state at any point in time
- **Schema Validation**: JSON Schema 2020-12 enforcement
- **Attachments**: Object storage for files and documents

#### Audit & Compliance

- **Tamper-evident Logging**: All operations logged immutably
- **Actor Tracking**: Every action tied to authenticated user
- **Event Streaming**: Audit events for downstream systems

#### Planning Insights Integration

- **CSV File Watcher**: Automatic processing of planning data
- **Batch Updates**: Efficient bulk DPP updates
- **Error Handling**: Quarantine and retry logic
- **API Upload**: Alternative to file watcher for cloud deployments

### Deployment Models

#### 1. **Local Development** (run-local.ps1)

- SQLite database
- No authentication required
- File watcher enabled
- Fast iteration cycle
- Best for: Development and testing

#### 2. **Docker Compose** (compose.yaml)

- Full service stack
- PostgreSQL, Keycloak, OPA, MinIO
- Production-like environment
- File watcher enabled
- Best for: Integration testing

#### 3. **Azure App Service** (infra/)

- Managed PostgreSQL
- Application Insights
- HTTPS with TLS 1.2+
- Auto-scaling
- CSV upload via API endpoint (no file watcher)
- Best for: Production deployment

---

## Data Flow

### DPP Query Flow (with Masking)

```mermaid
sequenceDiagram
    actor User
    participant Portal
    participant API
    participant JWT as JWT Middleware
    participant OPA
    participant Masking
    participant DB
    participant Audit

    User->>Portal: Request DPP
    Portal->>API: GET /dpp/{id}<br/>Authorization: Bearer {token}
    API->>JWT: Validate Token
    JWT->>JWT: Verify signature (JWKS)
    JWT->>JWT: Extract scopes & roles
    JWT->>OPA: Policy Query<br/>{user, method, path, access_tier}
    OPA-->>JWT: {allow: true, mask: [fields]}
    JWT->>DB: Query latest version
    DB-->>JWT: DPP Version + Payload
    JWT->>Masking: Apply mask rules
    Masking-->>JWT: Filtered payload
    JWT->>Audit: Log access event
    JWT-->>API: Response ready
    API-->>Portal: 200 OK + Masked DPP
    Portal-->>User: Display DPP
```

### DPP Creation Flow

```mermaid
sequenceDiagram
    actor User
    participant Portal
    participant API
    participant JWT as JWT Middleware
    participant Validator
    participant UID
    participant DB
    participant Audit

    User->>Portal: Create DPP
    Portal->>API: POST /dpp<br/>{product_id, payload}
    API->>JWT: Validate Token
    JWT->>Validator: Validate payload schema
    Validator-->>JWT: Schema valid ✓
    JWT->>UID: Extract & normalize DPP ID
    UID-->>JWT: Canonical ID
    JWT->>DB: Check if exists
    alt New DPP
        DB-->>JWT: Not found
        JWT->>DB: Create header + v1
    else Existing DPP
        DB-->>JWT: Found (lock for update)
        JWT->>DB: Append new version
    end
    JWT->>Audit: Log creation event
    JWT-->>API: Success
    API-->>Portal: 201 Created {dpp_id, version}
    Portal-->>User: Confirm creation
```

### Planning Insights Update Flow

```mermaid
sequenceDiagram
    participant Watcher as File Watcher
    participant Processor
    participant DB
    participant Audit
    participant DLQ as Dead Letter Queue

    Watcher->>Watcher: Detect CSV file
    Watcher->>Processor: Trigger processing
    Processor->>Processor: Parse CSV
    loop For each row
        Processor->>DB: Find DPP by product_id
        alt DPP Found
            DB-->>Processor: DPP record
            Processor->>DB: Update planning insights
            Processor->>Audit: Log update
        else Not Found
            DB-->>Processor: 404
            Processor->>DLQ: Queue for review
        end
    end
    Processor->>Audit: Log batch completion
    Processor->>Watcher: Success/Failure report
```

---

## Related Documentation

- [API Deployment Guide](./api-deployment.md) - Azure App Service deployment details
- [Security Guide](./security.md) - Authentication and authorization configuration
- [Data Model](./data-model.md) - Database schema and versioning
- [Policy Guide](./policy.md) - OPA policy authoring and testing

---

## References

- FastAPI: [https://fastapi.tiangolo.com/](https://fastapi.tiangolo.com/)
- Open Policy Agent: [https://www.openpolicyagent.org/](https://www.openpolicyagent.org/)
- Keycloak: [https://www.keycloak.org/](https://www.keycloak.org/)
- SQLAlchemy 2.0: [https://docs.sqlalchemy.org/](https://docs.sqlalchemy.org/)
- C4 Model: [https://c4model.com/](https://c4model.com/)
