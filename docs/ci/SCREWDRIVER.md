# Screwdriver.cd Integration for Zenbase

This document explains how Zenbase integrates with Screwdriver.cd for CI/CD automation.

## Overview

Zenbase uses Screwdriver.cd to automate:
- Building and testing code
- Running docker-compose for development
- Deploying to Fly.io staging and production
- Health checks and rollbacks

## Configuration Files

### `screwdriver.yaml`
Main Screwdriver configuration defining jobs and workflows:
- **main**: Lint, build, and test
- **build-images**: Build Docker images
- **deploy-dev**: Deploy with docker-compose
- **deploy-staging**: Deploy to Fly.io staging
- **deploy-production**: Deploy to Fly.io production
- **rollback**: Emergency rollback procedure

### `docker-compose.yml`
Base configuration for all environments with:
- Health checks for both services
- Named volumes for node_modules
- Custom network for service communication
- Environment variable defaults

### `docker-compose.prod.yml`
Production overrides with:
- Production build targets
- Nginx reverse proxy
- SSL configuration
- Always restart policy

### `docker-compose.test.yml`
Test environment with:
- Mock Supabase service
- Test-specific environment variables
- Isolated test network

## Quick Start

### Using Make Commands

```bash
# Show all available commands
make help

# Install dependencies
make install

# Build the application
make build

# Start with docker-compose
make up

# View logs
make logs

# Stop services
make down

# Run health checks
make health

# Deploy to different environments
make deploy-dev
make deploy-staging
make deploy-prod
```

### Using Scripts Directly

```bash
# Build
./scripts/build.sh

# Deploy
./scripts/deploy.sh development
./scripts/deploy.sh staging
./scripts/deploy.sh production

# Health check
./scripts/health-check.sh http://localhost:3000 http://localhost:5173
```

## Screwdriver Workflows

### PR Check Workflow
Triggered on pull requests:
```
main (lint, build, test)
```

### Deployment Pipeline
Triggered on main branch commits:
```
main → build-images → deploy-dev → deploy-staging → deploy-production
```

### Emergency Rollback
Manual trigger:
```
rollback (reverts to previous Fly.io release)
```

## Environment Variables

### Required for Development
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Required for Deployment
```bash
FLY_API_TOKEN=your-fly-token
```

### Optional
```bash
NODE_ENV=development|staging|production
CORS_ORIGIN=http://localhost:5173
VITE_API_URL=http://localhost:3000
```

## Docker Compose Usage

### Development
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Production
```bash
# Start with production overrides
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Testing
```bash
# Run tests
docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit
```

## Health Checks

Both services include health checks:

**Backend:**
- Endpoint: `http://localhost:3000/health`
- Interval: 10s
- Timeout: 5s
- Retries: 3

**Frontend:**
- Endpoint: `http://localhost:5173/`
- Interval: 10s
- Timeout: 5s
- Retries: 3

## Deployment Process

### Development
1. Code is pushed to feature branch
2. Screwdriver runs `main` job (lint, build, test)
3. PR is reviewed and merged

### Staging
1. Code is merged to main branch
2. Screwdriver builds Docker images
3. Deploys to Fly.io staging environment
4. Runs health checks
5. Notifies team

### Production
1. Staging deployment succeeds
2. Manual approval (optional)
3. Deploys to Fly.io production
4. Runs health checks
5. Notifies team

### Rollback
1. Issue detected in production
2. Trigger rollback workflow
3. Fly.io reverts to previous release
4. Health checks verify rollback

## Troubleshooting

### Docker Compose Issues

**Services won't start:**
```bash
# Check configuration
docker-compose config

# View logs
docker-compose logs

# Rebuild images
docker-compose build --no-cache
```

**Port conflicts:**
```bash
# Check what's using ports
lsof -i :3000
lsof -i :5173

# Kill processes
kill -9 <PID>
```

### Screwdriver Issues

**Build fails:**
- Check `screwdriver.yaml` syntax
- Verify environment variables are set
- Review build logs in Screwdriver UI

**Deployment fails:**
- Verify FLY_API_TOKEN is set
- Check Fly.io app exists
- Review deployment logs

**Health checks fail:**
- Verify services are running
- Check health check endpoints
- Review service logs

## Best Practices

1. **Always test locally first:**
   ```bash
   make build
   make up
   make health
   ```

2. **Use environment-specific configs:**
   - Development: `docker-compose.yml`
   - Production: `docker-compose.yml` + `docker-compose.prod.yml`
   - Testing: `docker-compose.yml` + `docker-compose.test.yml`

3. **Monitor health checks:**
   - Services must pass health checks before deployment proceeds
   - Failed health checks trigger automatic rollback

4. **Keep secrets secure:**
   - Never commit `.env` files
   - Use Screwdriver secrets for sensitive data
   - Rotate credentials regularly

## Integration with Fly.io

Screwdriver deploys to Fly.io using:
- `fly.toml` for production configuration
- `fly.staging.toml` for staging configuration
- Wildcard domain support for `*.zenbase.online`

## Next Steps

1. Set up Screwdriver.cd account
2. Connect repository to Screwdriver
3. Configure secrets (SUPABASE_URL, SUPABASE_ANON_KEY, FLY_API_TOKEN)
4. Test pipeline with a PR
5. Deploy to staging
6. Deploy to production

## Resources

- [Screwdriver.cd Documentation](https://docs.screwdriver.cd/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Fly.io Documentation](https://fly.io/docs/)
- [Zenbase README](./README.md)
