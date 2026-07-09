# CodeMySpec

Feedback widget + OAuth provider credentials for this app's CodeMySpec integration (ADR: pow-assent-integrations; wired by cms_gen.feedback_widget).

## Auth Type

oauth2

## Required Credentials

- `CODEMYSPEC_CLIENT_ID` — generated with the **Generate Credentials** button at https://codemyspec.com/app/projects/3ed0fe57-3568-4536-9f90-560d740cd8db
- `CODEMYSPEC_CLIENT_SECRET` — generated alongside the client ID
- `CODEMYSPEC_URL` — defaults to `https://codemyspec.com`; only set if using a different server

## Verify Script

.code_my_spec/qa/scripts/verify_codemyspec.sh

## Token Exchange Script

.code_my_spec/qa/scripts/exchange_codemyspec_token.sh

## Status

pending
