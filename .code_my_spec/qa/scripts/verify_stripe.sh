#!/bin/bash
# Verify Stripe credentials by fetching the account balance (read-only).
set -u

if [ -z "${STRIPE_SECRET_KEY:-}" ]; then
  echo '{"integration": "stripe", "status": "error", "error": "STRIPE_SECRET_KEY not set", "details": "export STRIPE_SECRET_KEY or add it to .env"}'
  exit 1
fi

response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/balance -u "${STRIPE_SECRET_KEY}:")
http_code=$(echo "$response" | tail -1)

if [ "$http_code" = "200" ]; then
  echo '{"integration": "stripe", "status": "ok", "details": "fetched /v1/balance with secret key"}'
else
  body=$(echo "$response" | sed '$d' | tr -d '\n' | head -c 200)
  echo "{\"integration\": \"stripe\", \"status\": \"error\", \"error\": \"HTTP ${http_code}\", \"details\": \"$(echo "$body" | sed 's/"/\\"/g')\"}"
  exit 1
fi
