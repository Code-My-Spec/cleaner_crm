# Qa Story Brief

## Tool

web (portal LiveViews behind magic-link session); curl for `POST /webhooks/stripe` (unauthenticated `:webhook` pipeline — payment confirmation/decline only arrives this way); psql for verifying `tips` table rows and cleaner earnings isolation.

## Auth

Portal (no password): `http://127.0.0.1:4100/portal/access/qa852paymenttoken1234567890abcd` — client "QA Payment852 Client" (email `qa-payment852@example.com`, `card_on_file: false` initially).

Cleaner (for the tip/no-tip earnings check): `qa-cleaner@cleanercrm.test` / `qa password 1234` at `/users/log-in`. This cleaner (id 2, display name "QA Cleaner Test") is assigned to the tip and no-tip test jobs.

Owner: `qa-owner@cleanercrm.test` / `qa password 1234` — not required for this story but available if cross-checking `/invoices` is useful.

## Seeds

Base seeds already applied. Story-specific data inserted directly via psql (no seed script changes needed, one-off entities):

Client `00dbd290-a4c5-4ab3-9b3d-8681c775c940` with these jobs/invoices, all $150.00 (`agreed_price_cents`/`amount_cents` 15000):

- `b09566b8-610a-4768-bacd-f90024e9f30a` — unpaid, no cleaner. Use for criterion 7238 (pay with new card + receipt email).
- `0149ab79-62a5-489d-9074-0f4486ba96e9` — status `charge_pending`, `stripe_payment_intent_id='pi_test_852_ok'`. Use for criterion 7239 (webhook confirms paid).
- `95d8bf44-67bd-44ba-b71c-c91a6a404558` — status `charge_pending`, `stripe_payment_intent_id='pi_test_852_declined'`. Use for criterion 7240 (webhook declines, stays unpaid).
- `0e28ca43-36ff-49be-983e-c31b2c7aab41` — unpaid, no cleaner. Use for criterion 7241 (save card on file).
- `86b53018-b892-4ec5-ab39-42893138e77b` — unpaid, job assigned to `qa-cleaner@cleanercrm.test`. Use for criterion 7242 (tip at payment).
- `a8cae918-166a-4e84-a037-8efede2cdfb7` — unpaid, job assigned to the same cleaner. Use for criterion 7243 (pay without tipping) — verify via `select * from tips where invoice_id='a8cae918-...'` (expect zero rows) rather than relying solely on the cleaner's aggregate `/field` pay-period total, since that cleaner has pre-existing earnings from other QA sessions that would muddy an exact-dollar assertion.
- `5ab6500b-7dab-493f-95aa-eb153c23a062` — already `paid`, $200.00. Combine with any of the unpaid ones above for criterion 7237 (view list shows both paid and unpaid with correct amounts/status).

## What To Test

- **View invoice list (7237):** open `/portal/invoices`. Expect `[data-test='invoice-row-5ab6500b-...']` showing "$200.00" and "Paid", and at least one unpaid row showing "$150.00" and "Unpaid".
- **Pay with a new card (7238):** click `[data-test='invoice-b09566b8-...-pay-button']`, submit `[data-test='invoice-b09566b8-...-payment-form']` with just `payment[card_token]=pm_card_visa` (the form hard-codes this as a hidden field — real Stripe Elements capture is deferred, same pattern as story 849's booking flow). Expect the page to reflect the submission (amount shown, status likely "Charge Pending" per the ADR — final "Paid" is webhook-driven, not synchronous). Check `/dev/mailbox` for a receipt email to `qa-payment852@example.com`.
- **Invoice marked paid on webhook (7239):** `curl -sS -X POST http://127.0.0.1:4100/webhooks/stripe -H "Content-Type: application/json" -d '{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_test_852_ok","metadata":{"invoice_id":"0149ab79-62a5-489d-9074-0f4486ba96e9"}}}}'`. Reload `/portal/invoices` — expect that row now shows "Paid".
- **Declined card leaves invoice unpaid (7240):** `curl -sS -X POST http://127.0.0.1:4100/webhooks/stripe -H "Content-Type: application/json" -d '{"type":"payment_intent.payment_failed","data":{"object":{"id":"pi_test_852_declined","metadata":{"invoice_id":"95d8bf44-67bd-44ba-b71c-c91a6a404558"}}}}'`. Reload — expect that row still shows "Unpaid" with its pay-button still present (client can retry).
- **Save a card on file (7241):** pay invoice `0e28ca43-...` with `payment[save_card]=true` alongside the card token. Expect `[data-test='card-on-file-badge']` to appear on the page afterward (client-level, not per-invoice). Verify via psql: `select card_on_file from clients where id='00dbd290-...'` should flip to `true`.
- **Add a tip at payment (7242):** pay invoice `86b53018-...` with `payment[tip_cents]=1000` alongside the card token. Verify via psql: `select amount_cents, cleaner_id from tips where invoice_id='86b53018-...'` shows one row, `amount_cents=1000`, `cleaner_id=2`. Then log in as `qa-cleaner@cleanercrm.test`, visit `/field`, and confirm `[data-test='pay-period-total']` reflects a nonzero total consistent with the added tip (exact aggregate may include other QA data — the psql row is the precise assertion).
- **Pay without tipping (7243):** pay invoice `a8cae918-...` leaving `payment[tip_cents]` blank. Verify via psql that `select count(*) from tips where invoice_id='a8cae918-...'` is 0 — no tip record created for this payment.
- Explore: try submitting a tip of `0` or a negative value; try paying an invoice that's already `paid` (no pay-button should exist to even attempt this); mobile spot-check `/portal/invoices` at 390x844 (expect the already-tracked shared-header overflow, don't refile).

## Result Path

Findings are filed via `create_issue` as discovered; final record is the `submit_qa_result` DB attempt (task id `f502a00a-d93f-4869-a16b-79a0498195df`). Screenshots: `.code_my_spec/qa/852/screenshots/`.
