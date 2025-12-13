#!/usr/bin/env bash
set -euo pipefail

# Pull secrets from Phase and run docker-compose with an env file.
# Intended for staging (Ona) automation using docker-compose.
# Requires: PHASE_SERVICE_TOKEN (CI-only).

if [[ -z "${PHASE_SERVICE_TOKEN:-}" ]]; then
  echo "PHASE_SERVICE_TOKEN is required (CI secret)." >&2
  exit 1
fi

ENV_FILE=${ENV_FILE:-.env.staging}
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.yml}

echo "Pulling Phase secrets into ${ENV_FILE}..."
phase secrets pull --env=staging --out "${ENV_FILE}"

echo "Validating required keys exist..."
if [[ ! -s "${ENV_FILE}" ]]; then
  echo "${ENV_FILE} is empty or missing." >&2
  exit 1
fi

echo "Starting docker-compose with ${ENV_FILE}..."
docker-compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d

echo "Compose up completed."
