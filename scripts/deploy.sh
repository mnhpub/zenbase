#!/bin/bash
# Deploy script for Screwdriver.cd pipeline

set -e

ENVIRONMENT=${1:-development}

echo "🚀 Deploying Zenbase to $ENVIRONMENT"

case $ENVIRONMENT in
  development)
    echo "Starting development environment with docker-compose..."
    docker-compose up -d
    echo "Running Ports:"
    docker-compose ps
    ;;
  
  staging)
    echo "Deploying to Fly.io staging..."
    if [ -z "$FLY_API_TOKEN" ]; then
      echo "❌ FLY_API_TOKEN not set"
      exit 1
    fi
    if [ -z "$PHASE_SERVICE_TOKEN" ]; then
      echo "❌ PHASE_SERVICE_TOKEN not set"
      exit 1
    fi
    fly deploy --config fly.staging.toml --remote-only --build-secret phase_token="$PHASE_SERVICE_TOKEN"
    ;;
  
  production)
    echo "Deploying to Fly.io production..."
    if [ -z "$FLY_API_TOKEN" ]; then
      echo "❌ FLY_API_TOKEN not set"
      exit 1
    fi
    if [ -z "$PHASE_SERVICE_TOKEN" ]; then
      echo "❌ PHASE_SERVICE_TOKEN not set"
      exit 1
    fi
    fly deploy --remote-only --build-secret phase_token="$PHASE_SERVICE_TOKEN"
    ;;
  
  *)
    echo "❌ Unknown environment: $ENVIRONMENT"
    echo "Usage: $0 [development|staging|production]"
    exit 1
    ;;
esac

echo "✅ Deployment to $ENVIRONMENT complete"
