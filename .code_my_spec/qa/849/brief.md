# Qa Story Brief

## Tool

web (browser for `/book/accept/:token` and `/schedule`); curl for `POST /webhooks/stripe` (unauthenticated `:webhook` pipeline — confirms/declines only arrive this way, never synchronously from the confirmation form per criteria 7233/7234's own spex).

## Auth

None needed to create leads or view `/book/accept/:token` (public token-link route, no login).

For the "confirmed booking appears for the business" check (criterion 7236), log in as the owner via the browser: navigate to `http://127.0.0.1:4100/users/log-in`, scroll `#login_form_password` into view, fill `input[name="user[email]"]` = `qa-owner@cleanercrm.test`, `input[name="user[password]"]` = `qa password 1234`, click the password form's submit button, then visit `/schedule`.

## Seeds

Base seeds already applied (`mix run priv/repo/qa_seeds.exs`) — account "QA Sparkle Cleaning Co" (`b4ecfdf7-95d9-4fc0-884a-353d9db1c473`), owner/cleaner confirmed users.

Each test scenario needs its OWN fresh lead (status transitions are one-way). Create one per scenario via the browser at `/book` (per-room, e.g. 2 bed/1 bath → $130.00) → fill the lead contact form → capture the acceptance token from the redirect URL `/book/accept/:token`, OR harvest directly:

```
psql -h localhost -d cleaner_crm_dev -c "select id, acceptance_token, status, total_cents, client_name from leads order by inserted_at desc limit 5;"
```

For the slot-unavailable scenario (criterion 7230), pre-seed a competing job at the exact date/time you're about to select in the browser (10 days out, 09:00–11:00):

```
psql -h localhost -d cleaner_crm_dev -c "insert into jobs (id, account_id, scheduled_date, start_time, end_time, status, inserted_at, updated_at) values (gen_random_uuid(), 'b4ecfdf7-95d9-4fc0-884a-353d9db1c473', current_date + 10, '09:00', '11:00', 'scheduled', now(), now());"
```

## What To Test

- **Slot selection (7228):** create a lead, visit `/book/accept/:token`. Fill `[data-test='slot-form']` with a date 10 days out and start time 09:00, submit. Expect it advances to show `[data-test='confirmation-form']` and `[data-test='policy-agreement-checkbox']`.
- **Slot becomes unavailable (7230):** on a NEW lead, pre-insert a competing job at the same date/time (see Seeds), select that slot, then submit the confirmation form with the policy checkbox checked. Expect `[data-test='slot-unavailable-error']`, no `[data-test='payment-pending']`, no `[data-test='booking-confirmed']`, and verify via psql that the lead's `stripe_payment_intent_id` is still null (no charge attempted).
- **Policy agreement required (7231/7232):** on a NEW lead, select an open slot, then submit the confirmation form WITHOUT checking the policy checkbox. Expect `[data-test='policy-required-error']`, no payment-pending/confirmed. Then check the box and resubmit — expect it proceeds to `[data-test='payment-pending']` (mirrors the two criteria on one lead, checking the negative first).
- **Valid card confirms via webhook (7233):** on a NEW lead, select a slot, submit confirmation with the policy checked (hidden field always sends `payment_method=pm_card_visa` — real Stripe Elements capture is deferred, this is documented/expected, not a gap to flag). Expect `payment-pending`. Then simulate the gateway's async confirmation: `curl -sS -X POST http://127.0.0.1:4100/webhooks/stripe -H "Content-Type: application/json" -d '{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_test_qa_849_ok","metadata":{"lead_id":"<lead-id>"}}}}'`. Reload `/book/accept/:token` — expect `[data-test='booking-confirmed']`.
- **Card declined via webhook (7234):** on a NEW lead, repeat through payment-pending, then POST `{"type":"payment_intent.payment_failed", ...}` with the same metadata shape. Reload — expect `[data-test='payment-declined-message']`, no `booking-confirmed`. Confirm the confirmation form re-appears so the client can retry with a different card.
- **Exact amount authorized (7235):** on the confirmed lead from the 7233 scenario, confirm `total_cents` on the lead equals the amount you'd expect from its rate-card inputs (no added fee) and that the accept page shows the same `$X.XX` both before and after confirmation, with no `[data-test='added-fee']` element ever appearing. Cross-check the Stripe Test adapter recorded the same amount: `psql -h localhost -d cleaner_crm_dev -c "select stripe_payment_intent_id, total_cents from leads where id = '<lead-id>';"`.
- **Confirmed booking visible to both sides + portal link (7236):** using the confirmed lead, log in as owner (see Auth) and visit `/schedule` — expect the client's name to appear on the board. Check `/dev/mailbox` (Swoosh local mailbox) for the confirmation email to the lead's client_email containing an `href` with "portal" in it (magic link). Then harvest that portal token from psql (`select token from portal_sessions order by inserted_at desc limit 1;`) for the next story's (850) reuse if helpful.
- Explore: try submitting the slot form with a past date, or a start time outside business hours; check for a validation message rather than an accepted booking. Try reloading `/book/accept/:token` mid-payment-pending (should still show payment-pending, not error). Try an unknown/garbage token at `/book/accept/bogus-token` — expect the "couldn't find that booking link" message, not a crash.

## Result Path

Findings are filed via `create_issue` as discovered; final record is the `submit_qa_result` DB attempt (task id `1704e78c-3e91-432d-8d53-1e42ee81583b`). Screenshots: `.code_my_spec/qa/849/screenshots/`.
