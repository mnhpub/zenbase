# Multi-stage build for Zenbase
FROM node:20-alpine AS frontend-builder

# Accept PHASE_SERVICE_TOKEN as build secret
ARG PHASE_SERVICE_TOKEN

RUN apk add --no-cache curl && curl -fsSL https://pkg.phase.dev/install.sh | sh -s -- --version 1.21.1

WORKDIR /app

COPY .phase.json ./

WORKDIR /app/frontend

COPY frontend/package*.json ./

RUN npm ci

COPY frontend/ ./

# Use PHASE_SERVICE_TOKEN for authentication during build
RUN --mount=type=secret,id=phase_token \
    PHASE_SERVICE_TOKEN=$(cat /run/secrets/phase_token 2>/dev/null || echo "$PHASE_SERVICE_TOKEN") \
    phase run --app "zenbase.online" --env "production" npm run build

# Backend stage
FROM node:20-alpine AS backend-builder

WORKDIR /app/backend

COPY backend/package*.json ./
RUN npm ci --only=production

COPY backend/ ./

# Final production stage
FROM node:20-alpine

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
CMD ["sh", "-c", "phase run --app \"zenbase.online\" --env \"development\" node backend/src/server.js"]
