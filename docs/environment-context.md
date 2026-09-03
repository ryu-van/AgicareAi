# Environment context

- Environment: local development workspace.
- Tenant/data scope: personal repository and synthetic SQLite fixtures only.
- Evidence: local `services/api` test fixtures, `DEV_AUTH_ENABLED=true` test coverage, and `API_BASE_URL` defaults to loopback for development.
- Allowed actions: source changes, local unit/integration-style tests, local builds and generated-artifact cleanup.
- Not selected: staging, UAT or production API/database; no production data or credentials were read.
- Release confirmation still required: production API URL, signing credentials, CI project, device matrix and named owners.

