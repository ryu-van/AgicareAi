# API Test Matrix — MVP

## Smoke suite

| Area | Check | Expected |
|---|---|---|
| Health | `GET /health` | `200`, `{status: ok}` |
| Auth | No token on protected route | `401`, safe error envelope |
| Identity | `Bearer dev:<UUID>` in local mode | Auto-provision profile + default `user` role |
| RBAC | Missing required role | `403 FORBIDDEN`, role is never taken from request |
| Knowledge | Filter by domain/subject and published status | Stable bounded page; drafts excluded |
| Grounding | Matching chat question | Deterministic answer with article citation and same domain |
| Grounding fallback | No matching article | Explicit no-source answer; no fabricated diagnosis |
| Validation | Empty chat content | `422`, field-level error |
| Ownership | User reads another user's resource | `404` or `403`, no data leak |
| Idempotency | Same write + same key twice | Same result, one record |
| Conflict | Same client event, different payload | `409 CONFLICT` |
| Rate limit | Exceed chat quota | `429` + `Retry-After` |
| Dependency | AI timeout | Stable `DEPENDENCY_TIMEOUT`, no fabricated answer |
| Privacy | Error/log inspection | No token, image, exact coordinates or full sensitive text |

## Test layers

1. Unit: validators, safety policy, citation mapper, idempotency service, sync conflict resolver.
2. API integration: FastAPI route + test database, auth claims and ownership policies.
3. Contract: validate responses against `packages/contracts/openapi.yaml`.
4. Mobile integration: offline outbox → retry → partial success → conflict UI.
5. Smoke: health/readiness after deployment; never use production user data.

## Minimum acceptance before MVP pilot

- Every protected endpoint has unauthorized and cross-user tests.
- Every write endpoint has duplicate/retry tests.
- Chat has empty input, no-citation, citation, unsafe/caution, duplicate idempotency, cross-user, rate-limit and payload-limit tests.
- Sync has applied, duplicate, conflict and rejected event tests.
- Test fixtures contain synthetic Vietnamese data only.
