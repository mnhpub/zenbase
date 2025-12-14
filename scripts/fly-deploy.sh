#!/bin/bash
set -euo pipefail

# Helper deploy script to pass Fly secrets into Docker build as BuildKit secrets
# Mirrors Fly.io snippet provided

deploy=(flyctl deploy)
touch /srv/.secrets

while read -r secret; do
  echo "export ${secret}=${!secret}" >> /srv/.secrets
  deploy+=(--build-secret "${secret}=${!secret}")
done < <(flyctl secrets list --json | jq -r ".[].name")

deploy+=(--build-secret "ALL_SECRETS=$(base64 --wrap=0 /srv/.secrets)")
${deploy[@]}
