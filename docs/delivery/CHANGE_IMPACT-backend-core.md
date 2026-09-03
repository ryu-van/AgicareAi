# Change Impact: Backend core vertical slice

- Owner: product/backend owner not assigned
- Scale/risk: S1
- Change type: additive, security-sensitive

## Evidence and search scope

Searched the FastAPI service, OpenAPI contract, API test matrix, feature breakdown, schema migrations, environment template and mobile package. No CI, deployment configuration, CODEOWNERS, Git remote or generated API client exists in this workspace.

## Consumers and owners

| Component/consumer | Owner | Effect | Verification | Rollout cohort |
|---|---|---|---|---|
| `apps/mobile` | unassigned | Can call the documented local API paths once integration begins. | API tests and OpenAPI-compatible responses | local developers |
| `packages/contracts/openapi.yaml` | unassigned | Defines response and auth compatibility. | route-level tests | local developers |
| Supabase PostgreSQL schema | unassigned | Future persistence target; no migration is applied in this slice. | disposable database migration later | development |

## Data/API/deployment dependencies

The change adds application code and an additive `/ready` OpenAPI operation. It requires a future authenticated Supabase/JWKS adapter and an applied PostgreSQL migration before production. Public behavior is additive under `/v1`; no existing client route is removed.

## Risks and unknowns

- JWT configuration is unknown, so real tokens must fail closed until configured.
- SQLite test behavior cannot prove Supabase RLS policies or PostgreSQL-specific migration behavior.
- No user-facing AI provider is integrated; chat uses a safe no-source response rather than fabricating an answer.
- Chat rate limiting is intentionally in-memory and process-local; replace it with a shared limiter before horizontal scaling.

## Rollout, abort, rollback/roll-forward

Run local API tests first. Deploy only after configuring real token verification, applying migrations to a disposable database and adding cross-user authorization tests against Postgres. Abort a rollout on any unverified-token acceptance, cross-user read/write, or mismatch with the OpenAPI response shapes. Roll forward with additive migrations/configuration; rollback application code without altering existing schema.

## Approval and follow-up

Production database migration, Supabase credentials and authentication settings require the backend owner to select a target explicitly.
