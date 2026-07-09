#!/bin/bash
# Verify Twilio credentials by fetching the account resource (read-only).
set -u

for var in TWILIO_ACCOUNT_SID TWILIO_AUTH_TOKEN; do
  if [ -z "$(eval echo "\${$var:-}")" ]; then
    echo "{\"integration\": \"twilio\", \"status\": \"error\", \"error\": \"$var not set\", \"details\": \"export $var or add it to .env\"}"
    exit 1
  fi
done

response=$(curl -s -w "\n%{http_code}" \
  "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}.json" \
  -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}")
http_code=$(echo "$response" | tail -1)

if [ "$http_code" = "200" ]; then
  echo '{"integration": "twilio", "status": "ok", "details": "fetched account resource with SID+token"}'
else
  echo "{\"integration\": \"twilio\", \"status\": \"error\", \"error\": \"HTTP ${http_code}\", \"details\": \"check TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN\"}"
  exit 1
fi
