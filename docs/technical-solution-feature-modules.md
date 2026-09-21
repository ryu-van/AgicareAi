# AgriAn — Technical Solution for Feature Modules

## Document control

| Field | Value |
|---|---|
| Audience | Product, mobile, API, data/AI, QA and release owners |
| Scope | Android Flutter client, FastAPI modular monolith and its future production integrations |
| Status | Proposed implementation blueprint; it distinguishes existing MVP behavior from target behavior |
| Source of truth | API behavior: `packages/contracts/openapi.yaml`; persistence: `services/api/db/migrations/`; requirements: `docs/requirements.md` |
| Owner | Unassigned — assign a product owner, API owner and mobile owner before Pilot |
| Review trigger | Any public API/schema/auth/AI-provider change, or before Pilot release |

## 1. Context and decisions

The repository is a monorepo with an Android-first Flutter client at
`apps/mobile_flutter` and a FastAPI modular monolith at `services/api`.
Local development currently uses SQLite and Dev Auth; production targets
Supabase Auth, PostgreSQL, Storage and pgvector. This document does **not**
assume those production integrations already exist.

Decisions:

1. Keep a modular monolith until there is an independently owned/scaled
   workload. Module boundaries are API routers, application services, domain
   repository ports and adapters; modules do not import another module's
   persistence implementation.
2. Treat the server database as the source of truth. The client owns an
   encrypted local cache/outbox only, never a competing authority.
3. Use additive contracts and migrations. A mobile release must tolerate the
   prior API version during rollout.
4. All user writes require a stable idempotency key. Offline events have a
   UUID `event_id`; retries reuse it.
5. All AI answers must be grounded in published, reviewed knowledge or return
   an explicit insufficiency/escalation response. Image diagnosis remains
   feature-flagged until its release gate is met.

## 2. Current state versus target

| Module | Current repository evidence | Target for a usable Pilot |
|---|---|---|
| Platform/core | Request ID, error handler, `/health`, `/ready`, Dev Auth, SQLite | JWT verification, production configuration validation, restricted CORS, metrics and alert ownership |
| Identity | `/v1/me` and consent endpoints; only `Bearer dev:<uuid>` is accepted | Supabase login/session, JWKS JWT verification, secure token storage, refresh/logout and consent audit |
| Domains/farm | Domain list and farm-summary/create API; Flutter farm UI | Persist active domain and farm context locally and server-side; validate subject/farm ownership |
| Knowledge | Subject/articles read path and synthetic seed articles | Reviewed source ingestion, revision/publish workflow, provenance and cache invalidation |
| Chat | Session/message routes, keyword safety state and fixture-style retrieval | Grounded RAG, provider timeout/circuit handling, mandatory citation validation, feedback and escalation handoff |
| Journal | Create-entry route and repository/model support | Full CRUD/list, image attachment workflow, local draft/outbox and conflict UX |
| Reminders | List/create API and UI | Update/delete/status operations, timezone-aware recurrence, Android local notifications and reconciliation |
| Offline sync | Batch endpoint deduplicates event IDs; UI only simulates a sync | Durable client store, real queue, batch flush, retry/backoff, conflict resolution and telemetry |
| Escalation | Urgent chat flag only | Consent-led request, expert directory, assignment/status and notification workflow |
| Diagnosis | Stub endpoint/adapter and prototype UI | Upload/quarantine, quality gate, calibrated model, evidence, safety policy, expert fallback and kill switch |

## 3. Shared architecture

```text
Flutter feature page
  -> feature repository/client -> authenticated HTTP API
  -> FastAPI router -> application service -> domain port
  -> SQLAlchemy repository / adapter (Postgres, Storage, AI, notifications)

Flutter local database
  -> outbox event -> POST /v1/sync/batch -> idempotent event ledger
```

### API module contract

Each module follows this shape:

```text
modules/<feature>/
  router.py       # HTTP validation, auth dependency, response mapping
  schemas.py      # Pydantic request/response types
  service.py      # use cases and transaction boundary
  repository.py   # feature port, when persistence is owned by the module
```

`core/` owns authentication, configuration, structured errors, logging,
rate-limits and idempotency. `adapters/` own calls to Supabase, storage, AI
and notifications. Register a router only in `modules/registry.py`; mobile
depends on API DTOs through `ApiClient` and feature repositories, not on
server rules.

### Shared HTTP behavior

- Prefix all public routes with `/v1`; extend schemas additively and return
  the standard error envelope from `docs/api-contract.md`.
- Require `Authorization: Bearer <access-token>` outside local Dev Auth.
- Return `X-Request-Id` and log it with redacted metadata.
- Require `Idempotency-Key` (16–128 characters) for create/update/delete and
  persist request hash plus response. Reuse with a different body returns
  `409 CONFLICT`.
- Paginate collection endpoints with a stable cursor before knowledge/journal
  data grows beyond the MVP fixtures.
- Use UTC for stored timestamps; send an IANA timezone with reminder rules
  and device-captured journal time.

## 4. Module solutions

### F0 — Identity, onboarding and consent

**Responsibilities.** Authenticate a person, establish a principal, maintain
profile/preferences, and record versioned consent. It does not own farm data
or roles beyond authorization checks.

**Flow.** Flutter authenticates with Supabase; `flutter_secure_storage` holds
access/refresh tokens. `ApiClient` injects the access token, retries once only
after a successful refresh, then forces sign-in while preserving unsent drafts.
FastAPI verifies JWT signature against cached Supabase JWKS, then validates
`iss`, `aud`, `exp` and `sub`. The API creates/updates the application profile
only after a valid principal is available.

**Endpoints.** Retain `GET/PATCH /v1/me` and `POST /v1/me/consents`; add
auth-provider endpoints only if Supabase client SDK cannot own that flow.
Consent writes contain `consent_type`, immutable policy version, timestamp and
actor. Logout revokes/clears local session and decryptable local user cache.

**Acceptance checks.** An expired token cannot access a resource; switching
accounts does not expose the prior local cache; consent history is append-only;
Dev Auth is rejected when `APP_ENV != local`.

### F1 — Domain and farm context

**Responsibilities.** Select a plant/animal domain, supported subject and
optional farm context that scopes knowledge, chat and records.

**Data/invariants.** `domain` is mandatory for chat/diagnosis. Farm records
belong to one user; exact location is never returned to other users. Active
domain and last selected farm are cached locally for offline navigation, but
the server validates ownership on every write.

**Implementation.** Preserve existing `/v1/domains`, `/v1/subjects` and
`/v1/farm` interfaces; add an explicit profile preference or `active_context`
record rather than a global client-only selector. The Flutter domain picker
loads supported subjects and passes the selected context into Chat, Knowledge,
Journal and Diagnosis feature repositories.

### F2 — Knowledge library

**Responsibilities.** Serve only published, attributed content by domain and
subject; manage editorial lifecycle separately from reader access.

**Read path.** `GET /v1/knowledge/articles` accepts domain, subject, query and
cursor; its response includes article ID, title, source, revision and reviewed
time. `GET /v1/knowledge/articles/{id}` returns a single published revision.
The client caches immutable article content keyed by `id:revision` and checks
the list ETag/revision before reuse.

**Editorial path.** Create a restricted admin module with draft → in-review →
published/archived transitions. Require source URL/document identity, locale,
reviewer, review due date and content owner. Publishing creates an immutable
revision and reindexes retrieval; archive removes the revision from retrieval
without deleting audit history.

**Guardrail.** Current seed data is synthetic and must not be presented as
reviewed expert content. Pilot requires a named content owner and review SLA.

### F3 — Safe chatbot and RAG

**Responsibilities.** Persist conversations, retrieve domain-scoped approved
knowledge, enforce safety policy, generate a grounded answer and attach
citations. It never presents a definitive diagnosis or prescribing advice.

**Synchronous MVP flow.**

```text
validate question/domain -> pre-safety classification -> retrieve published sources
-> generate structured draft -> post-safety/citation validation
-> persist message + citations + needs_expert -> return response
```

For production, create a provider port with a strict timeout budget, bounded
retry only for transient errors, per-user rate limits and a circuit breaker.
Retrieval uses domain/subject filters first, then hybrid vector/text ranking.
Generation is allowed only when retrieval passes a minimum evidence threshold.
Otherwise return a Vietnamese “not enough evidence” response with next steps.
Persist provider/model/prompt version and retrieval IDs for audit, but never
store secrets or raw images in logs.

The existing AI, RAG and vision adapters are placeholders; no external LLM or
pgvector behavior should be claimed until the adapter contract tests pass.

### F4 — Care journal

**Responsibilities.** Capture chronological observations and user actions for
a farm/batch/group. Use soft deletion to preserve auditability.

**Write flow.** The app writes the form and optional attachment metadata in a
local transaction, generates an idempotency key, then sends it immediately or
queues it. The API validates user/farm ownership, persists UTC timestamp plus
device timezone and returns the canonical entity version. A duplicate request
returns the original response; a stale entity version returns a conflict with
server summary for the user to resolve.

**Attachments.** Request a short-lived upload URL from the API, upload directly
to private storage, then attach an object ID—not a public URL—to the journal.
Validate MIME type/size, remove EXIF location where required, scan/quarantine
before publication, and delete orphaned uploads with a scheduled cleanup.

### F5 — Reminders

**Responsibilities.** Store a server-side reminder schedule and deliver a
best-effort device notification. Server state wins when devices disagree.

Store recurrence rule, IANA timezone, due time and state
(`pending|snoozed|completed|cancelled`). Flutter schedules the next local
occurrence after create/update/sync using `flutter_local_notifications` and
reconciles on app start, timezone change and sync completion. Notification
permission denial keeps the reminder functional in-app and visibly explains
the limitation.

### F6 — Offline outbox and sync

**Local schema.** Use a single local SQLite/Drift database with `entities`,
`outbox_events`, `attachments`, `sync_state` and `tombstones`. Encrypt
user-scoped data at rest where platform capability allows. Each outbox event
contains `event_id`, `entity`, `operation`, payload, entity version, created
time, retry count and state (`pending|sending|applied|conflict|failed`).

**Flush algorithm.** Lock one flusher; select up to 50 pending events in
creation order; mark sending atomically; call `POST /v1/sync/batch`; apply each
result atomically; retry transient failures with exponential backoff and jitter;
stop on authentication failure; expose conflicts to the user. Do not silently
overwrite a server change. The current server event ledger detects duplicate
or differently hashed events, but a production implementation must also apply
the allowed entity operation transactionally.

**Triggers.** App foreground, restored connectivity, manual retry and periodic
background execution where Android permits it. Background execution is an
optimization, never the only path.

### F7 — Expert escalation

Create only after a named operational owner and expert directory exist. An
escalation references a chat/journal/diagnosis item, contains selected evidence
and explicit sharing consent, and uses generalized location by default. States:
`requested -> triaged -> assigned -> responded -> closed` plus `cancelled`.
The API returns an honest expected-response policy; no SLA is implied before
one is operationally staffed. Notifications are adapter-driven and every
handoff is auditable.

### F8 — Image diagnosis

Keep this behind `diagnosis_enabled` until a release gate is approved. Flow:

```text
capture -> client size/compression check -> private upload -> API quality gate
-> vision extraction -> domain-filtered retrieval -> confidence calibration
-> safety policy -> top candidates/evidence or expert fallback
```

Do not return a disease conclusion from an uncalibrated confidence value. Each
supported class needs a Vietnam-relevant validated dataset, model card,
threshold, false-positive monitoring, human-review route and kill switch.
Low-quality/low-confidence results ask for more evidence or escalation.

## 5. Data, security and operations

| Area | Required control |
|---|---|
| Authorization | Verify JWT in API; apply user ownership in every repository query; enable/test Postgres RLS before production |
| Secrets | API/provider/service keys only in server/CI secret stores; never ship them in Flutter or logs |
| Privacy | Minimize profile/location, version consent, redact logs, private object storage and retention/deletion policy |
| Reliability | Per-dependency timeout, bounded retry, idempotent writes, explicit conflict results and readiness that checks dependencies |
| Observability | Request ID, structured redacted logs, module latency/error metrics, sync backlog/conflict count and AI safety/escalation counters |
| Release safety | Feature flags for real AI, diagnosis and escalation; cohort rollout; abort on elevated safety events, auth failures or sync conflicts |

## 6. Delivery order and verification

1. **Foundation:** production configuration, Supabase JWT adapter, secure
   mobile session and RLS verification.
2. **Pilot core:** reviewed knowledge workflow, real RAG provider adapter,
   citation/safety tests and named content owner.
3. **Reliability:** durable outbox, transactional server application of sync
   events, journal/reminder completion and Android notification reconciliation.
4. **Operations:** expert escalation only with staffed owner; diagnosis only
   after the explicit model/safety release gate.

For every module change: update OpenAPI and migrations first; add backend unit
and API-contract tests; add Flutter repository/widget tests; run
`python -m pytest services/api/tests -q`, `flutter analyze`, and `flutter test`.
Run Android emulator integration tests for auth, offline recovery and
notification flows. Deploy migrations additively before code that requires
them; use a feature flag for new behavior; retain a rollback-compatible API
until the minimum supported mobile version is retired.

## 7. Open decisions blocking production

1. Select initial pilot geography and supported crops/livestock.
2. Name product, technical, veterinary/crop-content, security and on-call
owners.
3. Approve authentication method and Supabase project/environment ownership.
4. Define knowledge-source licensing, review cadence, privacy retention and
expert escalation operating model.
5. Establish Pilot success/safety metrics and an incident escalation path.
