# Secrets Configuration

This guide documents all required environment variables and how to provide them for local development, CI/CD, and production. Never commit secrets to the repository.

## Summary by Component

### Backend (Node/Express)
- `SUPABASE_URL` (required): Supabase project URL
- `SUPABASE_ANON_KEY` (required): Supabase anonymous key
- `PORT` (optional, default `3000`): API port
- `CORS_ORIGIN` (recommended): Allowed frontend origin, e.g., `http://localhost:5173`
- `NODE_ENV` (optional): `development` | `test` | `production`

### Frontend (Vite/React)
- `VITE_SUPABASE_URL` (required): Supabase project URL
- `VITE_SUPABASE_ANON_KEY` (required): Supabase anonymous key
- `VITE_API_URL` (recommended): Backend API base, e.g., `http://localhost:3000`

### Worker (Elixir + Oban)
- `DATABASE_URL` (required): Postgres connection string for Ecto/Oban
  - Example: `postgres://postgres:password@localhost:5432/zenbase_test`

### Scripts / Migrations
- `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT` for `scripts/migrate.sh`

### CI/CD and Deployment
- `FLY_API_TOKEN` (Fly.io deployments in Screwdriver)

## Where They’re Used

- Backend code: `backend/src/lib/supabase.js`, `backend/src/server.js`
- Frontend code: `frontend/src/lib/supabase.ts`, `frontend/src/pages/Dashboard.tsx`
- Worker config: `worker/config/config.exs`
- Docker Compose: `docker-compose.yml`, `docker-compose.test.yml`
- Fly.io config: `fly.toml`
- Screwdriver: `screwdriver.yaml`

## Local Development Options

### Option A: Docker Compose
Compose already wires many variables from your shell.
```bash
# Export secrets in the current shell (recommended for dev)
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
export VITE_API_URL="http://localhost:3000"

# Start services
docker-compose up -d
```

### Option B: Per-App .env Files
Create `.env` files in `backend/` and `frontend/`. Do not commit these.

`backend/.env`:
```
NODE_ENV=development
PORT=3000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
CORS_ORIGIN=http://localhost:5173
```

`frontend/.env`:
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_API_URL=http://localhost:3000
```

### Worker (Elixir) locally
```bash
export DATABASE_URL="postgres://postgres:password@localhost:5432/zenbase_test"
cd worker
mix deps.get
mix ecto.migrate
iex -S mix
```

## Gitpod / Ona Environments

Use Gitpod Secrets so values aren’t committed:
```bash
gitpod environment secret set SUPABASE_URL "https://your-project.supabase.co"
gitpod environment secret set SUPABASE_ANON_KEY "your-anon-key"
```
The automations file exports `VITE_*` variables for the frontend.

## CI/CD (Screwdriver)

- Configure `FLY_API_TOKEN` for Fly.io deploy stages.
- Test pipeline spins up a Postgres service and uses `DATABASE_URL` for the worker.
- See `docs/ci/SCREWDRIVER.md` for more details.

## Fly.io (Production)

Use Fly Secrets instead of plain env variables:
```bash
fly secrets set SUPABASE_URL="https://your-project.supabase.co"
fly secrets set SUPABASE_ANON_KEY="your-anon-key"
```
If your worker runs as a separate service, set `DATABASE_URL` for it as well.

## Security Guidance

- Use per-environment secret stores (Gitpod Secrets, Fly Secrets, CI secret manager).
- Never commit `.env` with real values; `.env.example` files should contain placeholders only.
- Scope keys minimally; rotate keys regularly.
- Limit CORS to known origins in production.

## Quick Reference

- Backend required: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- Frontend required: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`
- Worker required: `DATABASE_URL`
- Deployments: `FLY_API_TOKEN` (CI), Fly Secrets for runtime values
