#!/bin/bash
# Verify Resend credentials by listing domains (read-only).
set -u

if [ -z "${RESEND_API_KEY:-}" ]; then
  echo '{"integration": "resend", "status": "error", "error": "RESEND_API_KEY not set", "details": "export RESEND_API_KEY or add it to .env"}'
  exit 1
fi

response=$(curl -s -w "\n%{http_code}" https://api.resend.com/domains \
  -H "Authorization: Bearer ${RESEND_API_KEY}")
http_code=$(echo "$response" | tail -1)

if [ "$http_code" = "200" ]; then
  echo '{"integration": "resend", "status": "ok", "details": "listed domains with API key"}'
else
  echo "{\"integration\": \"resend\", \"status\": \"error\", \"error\": \"HTTP ${http_code}\", \"details\": \"check RESEND_API_KEY\"}"
  exit 1
fi
