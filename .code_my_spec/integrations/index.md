# Integrations Index

Third-party integrations identified from ADRs. Each spec lives in this
directory; verify scripts live in `.code_my_spec/qa/scripts/`.

| Integration | Auth | Purpose (ADR) | Status |
|---|---|---|---|
| [stripe](stripe.md) | api_token | Payments: card-on-file, links, webhooks (payments-stripe) | pending |
| [twilio](twilio.md) | api_token | SMS reminders and cleaner alerts (sms-delivery) | pending |
| [resend](resend.md) | api_token | Transactional email (resend) | pending |
| [object_storage](object_storage.md) | api_token | Photo/export storage, S3-compatible (file-storage) | pending |
| [codemyspec](codemyspec.md) | oauth2 | Feedback widget + OAuth provider (pow-assent-integrations) | pending |

## Credentials needed from the engineer

Set these in `.env` at the repo root (Dotenvy loads it in dev), then run
each verify script:

```
STRIPE_SECRET_KEY=sk_test_...        # https://dashboard.stripe.com/test/apikeys
STRIPE_WEBHOOK_SECRET=whsec_...      # https://dashboard.stripe.com/test/webhooks
TWILIO_ACCOUNT_SID=AC...             # https://console.twilio.com
TWILIO_AUTH_TOKEN=...
TWILIO_FROM_NUMBER=+1...
RESEND_API_KEY=re_...                # https://resend.com/api-keys
S3_ENDPOINT=https://...              # Hetzner Object Storage or any S3-compatible
S3_REGION=...
S3_BUCKET=cleaner-crm-dev
S3_ACCESS_KEY_ID=...
S3_SECRET_ACCESS_KEY=...
CODEMYSPEC_CLIENT_ID=...             # Generate Credentials button:
CODEMYSPEC_CLIENT_SECRET=...         # https://codemyspec.com/app/projects/3ed0fe57-3568-4536-9f90-560d740cd8db
```
