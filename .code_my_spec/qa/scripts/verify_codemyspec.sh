#!/bin/bash
# Verify CodeMySpec OAuth2 client credentials via client_credentials exchange.
set -u

script_dir="$(cd "$(dirname "$0")" && pwd)"
response=$("$script_dir/exchange_codemyspec_token.sh" 2>&1)

if echo "$response" | grep -q '"access_token"'; then
  echo '{"integration": "codemyspec", "status": "ok", "details": "client_credentials token exchange succeeded"}'
else
  err=$(echo "$response" | tr -d '\n' | head -c 200 | sed 's/"/\\"/g')
  echo "{\"integration\": \"codemyspec\", \"status\": \"error\", \"error\": \"token exchange failed\", \"details\": \"$err\"}"
  exit 1
fi
