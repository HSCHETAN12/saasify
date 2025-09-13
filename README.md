# saasify
“Learning project: Multi-tenant SaaS with Spring Boot, Redis, Pulsar, Conductor, React.”
 [Learning Roadmap](./docs/roadmap.md)

 ## Quick Start
```bash
./scripts/dev-up.sh   # start infra
./mvnw spring-boot:run -pl auth-tenant-service


## Modules

| Folder                | Purpose                                                                 |
|------------------------|-------------------------------------------------------------------------|
| **gateway/**           | API Gateway – single entry point, handles routing, rate limiting, auth  |
| **auth-tenant-service/** | Authentication & Tenant Management – tenants, users, roles, JWT auth   |
| **project-service/**   | Project & Task Management – CRUD APIs scoped to tenants                 |
| **billing-service/**   | Billing & Entitlements – mock plans (e.g., limits on projects per plan) |
| **notification-service/** | Notification handler – consumes events (from Pulsar) and triggers alerts |
| **frontend/**          | React dashboard – tenant-aware UI for projects, tasks, admin            |
| **docker/**            | Infrastructure setup – Docker Compose for MySQL, Redis, Pulsar, Conductor |
| **scripts/**           | Helper scripts – start/stop infra, seed data, other developer utilities  |




## Architecture (at a glance)


                       SaaSify — High-level Architecture

┌──────────────────────────────┐
│          Frontend            │
│        (React / Vite)        │
│  - Stores JWT                │
│  - Sends headers:            │
│    Authorization: Bearer ... │
│    X-Tenant-Id: <tenant>     │
│    X-Request-Id: <uuid>      │
└──────────────┬───────────────┘
               │  HTTPS / JSON (REST)
               v
┌──────────────────────────────────────────────────────────┐
│                       API Gateway                        │
│  - Routes: /api/auth/** → Auth/Tenant                    │
│           /api/work/** → Project                         │
│           /api/billing/** → Billing                      │
│  - Cross-cutting:                                        │
│      * Authn/Authz (JWT)                                 │
│      * Rate limiting (per tenant, Redis counters)        │
│      * Request/trace ID (X-Request-Id)                   │
│      * Basic metrics & logs                              │
└───────┬───────────────┬───────────────────────┬─────────┘
        │               │                       │  (async events)
        │               │                       │
        v               v                       v
┌─────────────┐   ┌────────────────┐       ┌──────────────────┐
│ Auth/Tenant │   │  Project Svc   │       │  Billing (mock)  │
│  Service    │   │ (Projects/Tasks│       │  Plans & Limits  │
│ - Tenants   │   │  per tenant)   │       │  (entitlements)  │
│ - Users     │   │ - CRUD + cache │       │                  │
│ - Roles/JWT │   │ - Validates    │<──────┤  Enforce limits  │
└──────┬──────┘   │   tenant & plan│  REST └──────────────────┘
       │          └───────┬────────┘
       │                  │  emits events (project.created, task.created)
       │                  v
       │            ┌──────────────┐     consumes
       │            │ Notification │◀──────────────────────────┐
       │            │   Service    │                           │
       │            │  (mock email)│                           │
       │            └──────────────┘                           │
       │                                                      v v
       │        ┌─────────────────────────────────────────────────────┐
       │        │                       Pulsar                        │
       │        │  topics: saas.projects.events, saas.tasks.events    │
       │        └─────────────────────────────────────────────────────┘
       │
       v
┌──────────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│      auth_db         │     │      work_db     │     │      Redis        │
│ (users, tenants,     │     │ (projects, tasks │     │ - cache (GETs)    │
│  memberships, plans) │     │  with tenant_id) │     │ - rate limits     │
└──────────────────────┘     └──────────────────┘     └──────────────────┘

                 ┌───────────────────────────────┐
                 │          Conductor            │
                 │  Workflows (e.g.,             │
                 │   Provision Tenant):          │
                 │   - CreateTenant (HTTP)       │
                 │   - SeedTemplates (Worker)    │
                 │   - SendWelcomeEmail (Worker) │
                 └───────────────────────────────┘


## What this project does (and why it’s useful)
SaaSify is a small, multi-tenant “Projects & Tasks” platform designed to learn real SaaS patterns:
- Tenant isolation via `tenant_id`
- JWT auth & roles
- API gateway with per-tenant rate limits
- Redis caching for fast reads
- Apache Pulsar for async events
- Conductor workflows for multi-step processes
- Production-ish practices: retries, idempotency, logs, metrics


