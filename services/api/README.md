# API service

Backend core currently implements `/health`, `/ready`, published domains, protected chat session/message creation, journal creation and offline sync event deduplication. Chat uses a local, process-scoped 20 requests/minute limiter. Real Supabase JWT verification, a shared production rate limiter, RAG/AI provider calls, reminders and editor operations remain out of scope for this local slice.

Run the focused suite from the repository root:

```powershell
python -m pytest services/api/tests -q
```

Apply the empty local PostgreSQL schema once:

```powershell
python -m services.api.db.run_local_migrations
```

The runner applies `000_local_bootstrap.sql`, `001_initial_schema.sql` and `002_local_compat.sql`. It intentionally refuses a non-empty `public` schema and does not apply `002_rls.sql`, which requires Supabase `auth.uid()`.

Database design: [docs/database-schema.md](../../docs/database-schema.md).

FastAPI modular monolith. Feature/module breakdown nằm ở [docs/features.md](../../docs/features.md), API contract nằm ở [docs/api-contract.md](../../docs/api-contract.md), và OpenAPI draft ở [packages/contracts/openapi.yaml](../../packages/contracts/openapi.yaml).

Module đầu tiên nên triển khai là `chat` với citation và safety response; diagnosis/vision để sau khi có dataset và tiêu chí đánh giá.
