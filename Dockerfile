# syntax = docker/dockerfile:1

# Fly secrets helper stages
FROM flyio/flyctl:latest as flyio
FROM debian:bullseye-slim as fly-secrets

RUN apt-get update; apt-get install -y ca-certificates jq

COPY <<"EOF" /srv/deploy.sh
#!/bin/bash
deploy=(flyctl deploy)
touch /srv/.secrets

while read -r secret; do
  echo "export ${secret}=${!secret}" >> /srv/.secrets
  deploy+=(--build-secret "${secret}=${!secret}")
done < <(flyctl secrets list --json | jq -r ".[].name")

deploy+=(--build-secret "ALL_SECRETS=$(base64 --wrap=0 /srv/.secrets)")
${deploy[@]}
EOF

RUN chmod +x /srv/deploy.sh

COPY --from=flyio /flyctl /usr/bin

# Multi-stage build for Zenbase
FROM node:20-alpine AS frontend-builder

# Provide flyctl binary for optional use
COPY --from=flyio /flyctl /usr/bin

RUN apk add --no-cache curl && curl -fsSL https://pkg.phase.dev/install.sh | sh -s -- --version 1.21.1

WORKDIR /app
COPY .phase.json ./

WORKDIR /app/frontend
COPY frontend/package*.json ./

RUN --mount=type=secret,id=ALL_SECRETS \
  sh -lc 'if [ -f /run/secrets/ALL_SECRETS ]; then . /run/secrets/ALL_SECRETS; fi; npm ci'

COPY frontend/ ./

RUN --mount=type=secret,id=ALL_SECRETS \
  sh -lc 'if [ -f /run/secrets/ALL_SECRETS ]; then . /run/secrets/ALL_SECRETS; fi; phase run --app "zenbase.online" --env "production" npm run build'

# Backend stage
FROM node:20-alpine AS backend-builder

WORKDIR /app/backend

COPY backend/package*.json ./
RUN --mount=type=secret,id=ALL_SECRETS \
  sh -lc 'if [ -f /run/secrets/ALL_SECRETS ]; then . /run/secrets/ALL_SECRETS; fi; npm ci --only=production'

COPY backend/ ./

# Final production stage
FROM node:20-alpine
# Provide flyctl binary in final image (optional)
COPY --from=flyio /flyctl /usr/bin

RUN apk add --no-cache curl && curl -fsSL https://pkg.phase.dev/install.sh | sh -s -- --version 1.21.1

WORKDIR /app

# Copy Phase config
COPY .phase.json ./

# Copy backend
COPY --from=backend-builder /app/backend ./backend

# Copy frontend build
COPY --from=frontend-builder /app/frontend/dist ./frontend/dist

# Expose port
EXPOSE 3000

# Health check (checks backend health endpoint)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start backend (which now serves frontend)
CMD ["sh", "-c", "phase run --app \"zenbase.online\" --env \"production\" node backend/src/server.js"]
