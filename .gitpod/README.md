# Gitpod Automations for Zenbase

This directory contains Gitpod automation configuration for the Zenbase project.

## Configuration

The `automations.yaml` file defines tasks and services that can be run in your Gitpod environment.

## Required Secrets

This project requires two secrets to be configured:

- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anonymous key for client-side access

### Setting Secrets

Set secrets using the Gitpod CLI:

```bash
gitpod environment secret set SUPABASE_URL "https://your-project.supabase.co"
gitpod environment secret set SUPABASE_ANON_KEY "your-anon-key"
```

Or through the Gitpod dashboard at [app.gitpod.io/settings/secrets](https://app.gitpod.io/settings/secrets)

## Available Tasks

Run tasks using `gitpod automations task start <task-name>`:

- `install` - Install backend and frontend dependencies (auto-runs on environment start)
- `build` - Build the application
- `test` - Run tests with docker-compose
- `lint` - Run ESLint on frontend code
- `validate` - Validate docker-compose configuration
- `health-check` - Run health checks on services
- `sd-build` - Screwdriver CI build step
- `sd-test` - Screwdriver CI test step
- `sd-deploy` - Screwdriver CI deploy step

## Available Services

Start services using `gitpod automations service start <service-name>`:

- `backend` - Express.js backend API server (port 3000)
- `frontend` - React + Vite frontend application (port 5173)

## Screwdriver CI Integration

The project uses Screwdriver CI for orchestration. The Makefile contains targets that are called by Screwdriver:

- `make sd-build` - Build step
- `make sd-test` - Test step
- `make sd-deploy` - Deploy step

All Screwdriver tasks have access to the `SUPABASE_URL` and `SUPABASE_ANON_KEY` secrets.

## Usage

### Load the automations file

```bash
gitpod automations update .gitpod/automations.yaml
```

### Set as default for this environment

```bash
gitpod automations update -s .gitpod/automations.yaml
```

### Start development environment

```bash
gitpod automations service start backend
gitpod automations service start frontend
```

### Run a task

```bash
gitpod automations task start build
```

### View logs

```bash
gitpod automations service logs backend
gitpod automations task logs build
```
