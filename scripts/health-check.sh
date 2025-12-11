#!/bin/bash
# Health check script for Screwdriver.cd pipeline

set -e

BACKEND_URL=${1:-http://localhost:3000}
FRONTEND_URL=${2:-http://localhost:5173}
MAX_RETRIES=30
RETRY_DELAY=2

echo "🏥 Running health checks"

# Check backend
echo "Checking backend at $BACKEND_URL..."
for i in $(seq 1 $MAX_RETRIES); do
  if curl -sf "$BACKEND_URL/health" > /dev/null; then
    echo "✅ Backend is healthy"
    break
  fi
  
  if [ $i -eq $MAX_RETRIES ]; then
    echo "❌ Backend health check failed after $MAX_RETRIES attempts"
    exit 1
  fi
  
  echo "Waiting for backend... (attempt $i/$MAX_RETRIES)"
  sleep $RETRY_DELAY
done

# Check frontend
echo "Checking frontend at $FRONTEND_URL..."
for i in $(seq 1 $MAX_RETRIES); do
  if curl -sf "$FRONTEND_URL" > /dev/null; then
    echo "✅ Frontend is healthy"
    break
  fi
  
  if [ $i -eq $MAX_RETRIES ]; then
    echo "❌ Frontend health check failed after $MAX_RETRIES attempts"
    exit 1
  fi
  
  echo "Waiting for frontend... (attempt $i/$MAX_RETRIES)"
  sleep $RETRY_DELAY
done

echo "✅ All health checks passed"
