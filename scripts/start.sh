#!/usr/bin/env sh
set -eu

# Start backend in background
cd /app/backend
npm start &
BACKEND_PID=$!

# Wait for backend health
HEALTH_URL="http://0.0.0.0:3000/health"
MAX_RETRIES=60
SLEEP_SECONDS=1

retry=0
until curl -fsS "$HEALTH_URL" >/dev/null 2>&1; do
  retry=$((retry+1))
  if [ "$retry" -ge "$MAX_RETRIES" ]; then
    echo "Backend health check failed after $MAX_RETRIES seconds"
    kill "$BACKEND_PID" || true
    exit 1
  fi
  sleep "$SLEEP_SECONDS"
done

echo "Backend healthy; starting frontend"

# Serve built frontend on port 80
cd /app/frontend
exec serve -s /app/frontend/dist -l tcp://0.0.0.0:80
