# Context Packet: CONTEXT-backend-core

packet_version: 1
delivery_or_run_id: backend-core
updated_at_utc: 2026-08-25T00:00:00Z
repository: D:\tai nguyen\DuAn\agricare-ai
base_commit: not-applicable (workspace is not a Git repository)
branch_or_worktree: D:\tai nguyen\DuAn\agricare-ai
environment: local
tenant_scope: unknown
objective: Implement the first executable FastAPI backend core for the documented MVP contract.
current_state: verified-local
next_owner: Codex
next_action: Hand off the local backend slice; configure Supabase JWT validation before any shared deployment.
stop_condition: An external Supabase database, production credentials, or deployment is required.

## Immutable Anchors

- FACT: `services/api/app/main.py` only exposes `GET /health`.
- FACT: `packages/contracts/openapi.yaml` defines domains, chat, journal, and sync endpoints.
- FACT: `services/api/requirements.txt` declares FastAPI, Pydantic settings, SQLAlchemy, Alembic, HTTPX, and pytest.
- FACT: no Git repository, remote, runtime database URL, or active Supabase target was detected.

## Delivery Contract

- Scope: local FastAPI foundation plus the currently executable OpenAPI endpoints for domains, chat, journal, and sync; tests with a local SQLite database.
- Non-goals: Supabase deployment, real JWT/JWKS integration, AI-provider calls, knowledge-editor endpoints, reminders, diagnosis, and any destructive migration.
- Acceptance criteria:
  - AC-1: protected routes reject missing/invalid authentication with the documented error envelope.
  - AC-2: chat, journal, and sync writes validate input, enforce ownership, and handle idempotent retries.
  - AC-3: the local test suite covers health, validation, idempotency, and cross-user protection.

## Fact Ledger

| ID | Label | Statement | Evidence | Confidence | Owner |
|---|---|---|---|---|---|
| CTX-FACT-001 | FACT | API stack is Python 3.12, FastAPI 0.115.6, SQLAlchemy 2.0.36 and pytest 9.0.3. | local package inspection | high | Codex |
| CTX-FACT-002 | FACT | Product data is user-owned and the schema specifies RLS in Supabase. | `docs/database-schema.md`, `002_rls.sql` | high | Codex |
| CTX-FACT-003 | FACT | Local environment has no configured runtime `DATABASE_URL` or selected Supabase target. | `.env.example` contains only templates; environment inspection | high | Codex |

## Assumption and Unknown Ledger

| ID | Label | Statement | Why unresolved | Validate/resolve by | Owner | Blocks |
|---|---|---|---|---|---|---|
| CTX-UNK-001 | UNKNOWN | Supabase JWT issuer, audience and JWKS URL are not configured. | No active Supabase project was supplied. | Add production auth adapter before deployment. | Product/backend owner | production only |
| CTX-ASSUME-001 | ASSUMPTION | SQLite is sufficient for local API tests; PostgreSQL migration remains the production schema source. | No database target is available. | Run migrations against disposable Supabase/Postgres. | Codex | no |

## Decision Ledger

| ID | Decision | Inputs | Rationale | Reversible | Owner | Supersedes |
|---|---|---|---|---|---|---|
| CTX-DEC-001 | Use a local SQLite adapter only in tests; keep production database configuration explicit. | CTX-FACT-001, CTX-FACT-003 | Enables executable behavior without accessing an external system. | yes | Codex | none |
| CTX-DEC-002 | Keep real bearer-token verification behind an adapter; tests override the principal dependency. | API contract, CTX-UNK-001 | Avoids accepting unverified tokens in production. | yes | Codex | none |
| CTX-DEC-003 | Use FastAPI ownership checks for local PostgreSQL and Supabase RLS as production defense in depth. | Local PostgreSQL has no `auth.uid()`; option 1 selected by user | Keeps local setup simple while preserving database-level protection in Supabase. | yes | User/Codex | none |

## Artifact Index and Invalidations

- Consumed: `packages/contracts/openapi.yaml`, `docs/api-contract.md`, `docs/features.md`, `docs/database-schema.md`.
- Produced: this packet, change-impact record, backend source and tests.
- Invalidated/superseded: none.

## Verification

- FACT: `python -m pytest services/api/tests -q` passed with 8 tests on local SQLite fixtures.
- FACT: `python -m compileall -q services/api/app` passed.
- FACT: the OpenAPI path list matches FastAPI's implemented path list for this slice.
- FACT: local PostgreSQL migration ran successfully with 17 public tables, four roles and the `sync_events.payload_hash` compatibility column.
- FACT: a read-only API smoke check returned `plant` and `animal` from local PostgreSQL.
- UNKNOWN: Supabase migration/RLS rehearsal and real JWT/JWKS verification have not run.

## Resume Checklist

- [x] Confirm repository and environment evidence.
- [x] Read unresolved auth/database assumptions.
- [x] Confirm implementation remains local and non-destructive.
