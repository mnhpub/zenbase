# Ona Agent Guide (AGENTS)

This document explains how the Ona Agent fits into the Zenbase project: what it does, how it interacts with services, and how to run, extend, and operate it safely.

## Overview

- Purpose: Automate tenant onboarding and synchronization tasks and assist the platform with background, idempotent workflows.
- Scope: Non-UI actor interacting with the API and database via well-defined contracts; runs locally for dev and in CI/CD or worker environments for staging/production.
- Core dependencies: Postgres (Supabase), Zenbase Backend API, Oban-based worker (Elixir), project secrets.

## Architecture & Data Flow

- Frontend (React) authenticates users with Supabase and calls the Backend API.
- Backend (Express) enforces tenant context via subdomain or `?tenant` param and verifies Supabase JWTs.
- Worker (Elixir + Oban) performs background jobs, notably onboarding synchronization against the database via RPC.
- Supabase (Postgres with RLS) stores multi-tenant data and exposes RPC such as `set_tenant_context` and `rpc_onboarding_sync_tenant`.

High-level path for onboarding automation:
1. A tenant is created or updated (via DB migration, admin action, or API).
2. The onboarding job/worker runs an RPC to initialize/update tenant resources.
3. Backend exposes tenant-scoped routes the agent can query to verify provisioning status and admin assignments.

## Agent Responsibilities

- Onboarding Sync: Execute `rpc_onboarding_sync_tenant(tenant_id, onboarding_id, params)` via the worker pipeline and confirm success.
- Validation: Query tenant-scoped Backend endpoints to verify provisioning status and admin assignments.
- Observability: Emit concise logs and surface errors for retry/triage.

## Relevant Code

- Backend
  - Tenant context middleware: `backend/src/middleware/tenant.js`
  - Auth middleware (Supabase JWT): `backend/src/middleware/auth.js`
  - Tenant API routes: `backend/src/routes/tenant.js`
  - Supabase client + RLS context: `backend/src/lib/supabase.js`
- Worker (Elixir)
  - Repo + DB config: `worker/lib/my_app/repo.ex`, `worker/config/config.exs`
  - Onboarding worker: `worker/lib/my_app/workers/onboarding_sync_worker.ex`
- Database (SQL Migrations)
  - Supabase mocks and initial schema: `data/migrations/*`

## Backend API Endpoints (Agent-Consumable)

All tenant endpoints require tenant context via subdomain or `?tenant=slug`.
- Public: `GET /health`
- Tenant: `GET /api/v1/tenant/info` (no auth) — basic tenant information
- Tenant: `GET /api/v1/tenant/dashboard` (auth required) — tenant dashboard data
- Tenant: `GET /api/v1/tenant/admins` (auth required) — list of admins for tenant

Authentication:
- Use Supabase JWTs in the `Authorization: Bearer <token>` header for endpoints that require auth.

## Worker Job: Onboarding Sync

Implementation: `MyApp.Workers.OnboardingSyncWorker`.
- Input: `tenant_id` (UUID), `onboarding_id` (UUID), `params` (JSON)
- Behavior: Calls `SELECT public.rpc_onboarding_sync_tenant($1::uuid, $2::uuid, $3::jsonb)`
- Retries: Managed by Oban (queue `onboarding`, `max_attempts: 5`, uniqueness period 60s)
- Output: Resulting JSON from the RPC, bubbled back for logging/observability

Run locally (example):
1. Ensure Postgres is up and `DATABASE_URL` points to your DB.
2. From `worker/`: `mix deps.get && mix ecto.migrate && iex -S mix`
3. Enqueue a job (example snippet within IEx):
   ```elixir
   args = %{"tenant_id" => "<uuid>", "onboarding_id" => "<uuid>", "params" => %{"dry_run" => false}}
   Oban.insert!(MyApp.Workers.OnboardingSyncWorker.new(args))
   ```

## Local Development

- Docker Compose: `docker-compose up -d` starts backend and frontend.
- API base URL: `http://localhost:3000`
- Frontend: `http://localhost:5173`
- CORS: Configure `CORS_ORIGIN` to match your frontend origin (defaults handled in compose).
- Worker: Run separately (requires Postgres). Set `DATABASE_URL` and start the worker app.

## Deployment

- Fly.io (production): See `fly.toml` and repo `README.md` for deployment steps.
- Screwdriver (CI/CD): See `docs/ci/SCREWDRIVER.md` and pipeline `screwdriver.yaml`.
- Secrets: Provision via platform secret stores (Fly Secrets, Screwdriver env, Gitpod Secrets) — see `docs/secrets/README.md`.

## Extending the Agent

- New Jobs: Add Oban workers under `worker/lib/my_app/workers/` with clear inputs/outputs.
- New APIs: Implement routes under `backend/src/routes/` guarded by tenant + auth middleware.
- Data Contracts: Prefer RPCs for atomic operations and RLS-safe access; update SQL migrations accordingly.

## Troubleshooting

- Missing env vars: Backend or worker will error on missing required environment variables.
- CORS errors: Ensure `CORS_ORIGIN` is set to your frontend origin when testing cross-origin calls.
- Auth failures: Confirm Supabase tokens are valid and carry required claims.
- DB/RPC errors: Check Postgres logs and ensure required RPCs (e.g., `rpc_onboarding_sync_tenant`) exist in your schema.

## References

- Secrets configuration: `docs/secrets/README.md`
- CI docs: `docs/ci/SCREWDRIVER.md`
- Project README: `README.md`
cd backend && npm run dev
