# Root production Dockerfile for backend + frontend
# Scout-recommended base: node:22-alpine

# -------- deps (runtime deps only) --------
FROM node:22-bookworm-slim AS deps
WORKDIR /app

RUN apt-get update; apt-get install -y ca-certificates jq

# Phase
ENV VERSION=1.21.1
RUN apt-get install -y curl && curl -fsSL https://pkg.phase.dev/install.sh | sh -s -- --version $VERSION

# Backend deps
COPY backend/package.json backend/package-lock.json ./backend/
RUN --mount=type=secret,id=ALL_SECRETS --mount=type=cache,target=/root/.npm \
	sh -lc 'cd backend && [ -f /run/secrets/ALL_SECRETS ] && eval "$(base64 -d /run/secrets/ALL_SECRETS)" || true; npm ci --omit=dev'

# Frontend deps
COPY frontend/package.json frontend/package-lock.json ./frontend/
RUN --mount=type=secret,id=ALL_SECRETS --mount=type=cache,target=/root/.npm \
	sh -lc 'cd frontend && [ -f /run/secrets/ALL_SECRETS ] && eval "$(base64 -d /run/secrets/ALL_SECRETS)" || true; npm ci --omit=dev'

# -------- build (dev deps + build outputs) --------
FROM deps AS build
WORKDIR /app

# Copy sources
COPY backend ./backend
COPY frontend ./frontend

# Backend build (ensure dev deps available during build)
RUN --mount=type=secret,id=ALL_SECRETS --mount=type=cache,target=/root/.npm \
	sh -lc 'cd backend && [ -f /run/secrets/ALL_SECRETS ] && eval "$(base64 -d /run/secrets/ALL_SECRETS)" || true; npm ci && npm run build'

# Frontend build
RUN --mount=type=secret,id=ALL_SECRETS --mount=type=cache,target=/root/.npm \
	sh -lc 'cd frontend && [ -f /run/secrets/ALL_SECRETS ] && eval "$(base64 -d /run/secrets/ALL_SECRETS)" || true; npm ci && npm run build'

# -------- runtime (single container runs both) --------
FROM node:22-bookworm-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production

# Copy runtime deps
COPY --from=deps /app/backend/node_modules /app/backend/node_modules
COPY --from=deps /app/frontend/node_modules /app/frontend/node_modules

# Copy backend source (no build output for Node backend)
COPY --from=build /app/backend/src /app/backend/src
COPY --from=build /app/frontend/dist /app/frontend/dist

# Copy minimal app metadata for npm start scripts
COPY backend/package.json /app/backend/package.json
COPY frontend/package.json /app/frontend/package.json

# Copy start script to orchestrate bring-up order
COPY scripts/start.sh /app/scripts/start.sh
RUN chmod +x /app/scripts/start.sh

# Install a lightweight static server for frontend
RUN npm install -g serve

# Expose only frontend on 80 (and optionally 443 for TLS termination upstream)
EXPOSE 80
EXPOSE 443

# Start backend first, wait for health, then start frontend
CMD ["/app/scripts/start.sh"]
