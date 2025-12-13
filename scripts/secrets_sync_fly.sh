#!/usr/bin/env bash
set -euo pipefail

# Sync application secrets from Phase to Fly app secrets, then deploy.
# Requires: PHASE_SERVICE_TOKEN (CI-only), FLY_APP_NAME, optionally FLY_REGION.

if [[ -z "${PHASE_SERVICE_TOKEN:-}" ]]; then
  echo "PHASE_SERVICE_TOKEN is required (CI secret)." >&2
  exit 1
fi

if [[ -z "${FLY_APP_NAME:-}" ]]; then
  echo "FLY_APP_NAME is required (target Fly app)." >&2
  exit 1
fi

ENV_FILE=${ENV_FILE:-.env.production}

echo "Pulling Phase secrets into ${ENV_FILE}..."
phase secrets pull --env=production --out "${ENV_FILE}"

echo "Validating required keys exist..."
if [[ ! -s "${ENV_FILE}" ]]; then
  echo "${ENV_FILE} is empty or missing." >&2
  exit 1
fi

echo "Setting Fly secrets..."
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  fly secrets set "$key=$value" --app "$FLY_APP_NAME"
done < "${ENV_FILE}"

echo "Deploying to Fly..."
if [[ -n "${FLY_REGION:-}" ]]; then
  fly deploy --app "$FLY_APP_NAME" --region "$FLY_REGION"
else
  fly deploy --app "$FLY_APP_NAME"
fi

echo "Fly deploy completed."
