# Stripe

Payment processing: card-on-file, payment links, webhooks (ADR: payments-stripe).

## Auth Type

api_token

## Required Credentials

- `STRIPE_SECRET_KEY` — secret API key (test mode `sk_test_...` for now). Get it at https://dashboard.stripe.com/test/apikeys
- `STRIPE_WEBHOOK_SECRET` — webhook signing secret (`whsec_...`), created when adding a webhook endpoint at https://dashboard.stripe.com/test/webhooks (needed at runtime, not checked by the verify script)

## Verify Script

.code_my_spec/qa/scripts/verify_stripe.sh

## Status

pending
