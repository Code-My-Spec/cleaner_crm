# Resend

Transactional email: auth emails, client reminders, invitations (ADR: resend).

## Auth Type

api_token

## Required Credentials

- `RESEND_API_KEY` — API key (`re_...`) from https://resend.com/api-keys; a verified sending domain is needed for production at https://resend.com/domains

## Verify Script

.code_my_spec/qa/scripts/verify_resend.sh

## Status

pending
