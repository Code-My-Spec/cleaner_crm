#!/bin/bash
# Exchange CodeMySpec OAuth2 client credentials for an access token.
# Prints the raw token-endpoint JSON response to stdout.
set -u

CODEMYSPEC_URL="${CODEMYSPEC_URL:-https://codemyspec.com}"

for var in CODEMYSPEC_CLIENT_ID CODEMYSPEC_CLIENT_SECRET; do
  if [ -z "$(eval echo "\${$var:-}")" ]; then
    echo "{\"error\": \"$var not set\"}" >&2
    exit 1
  fi
done

curl -s -X POST "${CODEMYSPEC_URL}/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${CODEMYSPEC_CLIENT_ID}" \
  -d "client_secret=${CODEMYSPEC_CLIENT_SECRET}"
