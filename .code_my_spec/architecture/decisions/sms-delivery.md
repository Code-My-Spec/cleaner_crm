# SMS Delivery — Twilio via Req behind a Delivery behaviour

**Status:** Accepted

## Context

Stories 837 (client reminders with confirm/reschedule) and 843 (cleaner schedule-change alerts) need reliable SMS. Research flags fragile reminder delivery (blocked numbers, silent failures) as an unresolved incumbent complaint, so delivery status must be tracked per message.

## Options Considered

- **Twilio REST API via Req** — no heavy SDK needed; Req is already a dependency; full delivery-status callbacks.
- **ex_twilio** — wraps the same API but adds a dependency with sporadic maintenance.
- **Telnyx/Plivo** — cheaper per message but smaller ecosystems.

## Decision

Call the Twilio Messages API directly with Req, wrapped in a `CleanerCrm.Notifications.Delivery` behaviour with `Twilio` and `Test` adapters. Persist provider message SIDs and consume Twilio status callbacks to mark delivered/failed on `Notification` records; failures surface in the office delivery log (story 837) and trigger the unacknowledged-alert escalation path (story 843).

## Consequences

- A2P 10DLC registration is required for US SMS; must be documented in deployment runbook.
- Email channel continues through Resend (pre-made ADR); the Delivery behaviour routes per channel.
- Delivery-status webhooks add a public controller endpoint that must verify Twilio signatures.
