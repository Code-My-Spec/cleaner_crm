# Twilio

SMS delivery for client reminders and cleaner schedule-change alerts (ADR: sms-delivery).

## Auth Type

api_token

## Required Credentials

- `TWILIO_ACCOUNT_SID` — account SID (`AC...`) from https://console.twilio.com
- `TWILIO_AUTH_TOKEN` — auth token from the same console page
- `TWILIO_FROM_NUMBER` — an SMS-capable phone number purchased in the console (E.164 format, e.g. `+15551234567`); A2P 10DLC registration required for US traffic before production sends

## Verify Script

.code_my_spec/qa/scripts/verify_twilio.sh

## Status

pending
