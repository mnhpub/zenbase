# Secrets Manifest

Canonical overview of application secrets across environments, owners, and rotation.

## Principles
- Phase is the source of truth for app-level secrets.
- CI uses `PHASE_SERVICE_TOKEN` to fetch secrets; token is CI-only.
- Fly secrets are injected at deploy/runtime via `fly secrets set`.
- Staging uses docker-compose with `--env-file`.

## Categories
- APP_*: Application configuration (Phase-managed, mirrored to all envs).
- SUPABASE_*: Supabase keys (Phase-managed, mirrored).
- FLY_*: Fly operational tokens (stored in CI/platform, not Phase).
- CI_*: CI-only variables (stored in CI secret store).

## Rotation
1. Rotate in Phase → sync staging → validate.
2. Sync production via Fly secrets → validate.
3. Record rotation in this manifest and notify owners.

## Required Keys (example)
- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY
- CORS_ORIGIN
- DATABASE_URL
