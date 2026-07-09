# Qa Story Brief — 836: Invoice completed jobs and collect payment

## Tool

web (LiveViews under `:browser` + `:require_authenticated_user`) for job
completion and invoice pages; `curl` for the two public, unauthenticated
surfaces — `/pay/:token` (`:public` pipeline) and `/webhooks/stripe`
(`:webhook` pipeline).

## Auth

- Login URL: `http://127.0.0.1:4100/users/log-in`. Password form fields
  are namespaced per-form: use `#login_form_password_email` (NOT the
  generic `input[name="user[email]"]`, which matches the magic-link
  form first) and `#login_form_password button[name='user[remember_me]']`.
- Owner creds: `qa-owner@cleanercrm.test` / `qa password 1234`. The owner
  is an account `:owner`, so `FieldLive.Job`'s office-staff check lets
  them open and complete ANY job, assigned or not — no cleaner login
  needed for this story.

## Seeds

1. `mix run priv/repo/qa_seeds.exs` (base owner/cleaner/account, idempotent).
2. `mix run priv/repo/qa_seeds_836.exs` (story-specific, not idempotent —
   re-run creates fresh rows) — creates:
   - **QA Card Client 836** (`card_on_file: true`) + property "836 Card St"
   - **QA NoCard Client 836** (`card_on_file: false`) + property "837 NoCard Ave"
   - Two invoices seeded directly in `:charge_pending`, each with a
     completed job carrying real proof-of-work (2 checklist items with
     before/after photos each), for the webhook-decision criteria:
     - **DECLINE test invoice** — `stripe_payment_intent_id: pi_qa_836_declined`
     - **SUCCESS test invoice** — `stripe_payment_intent_id: pi_qa_836_succeeded`

   Print the client/property ids and both invoice ids/uuids on
   completion — the tester needs the invoice UUIDs for the webhook curl
   calls (payload `data.object.metadata.invoice_id`) and can navigate to
   `/invoices` to find their `/invoices/:id` URLs directly rather than
   parsing output.

## What To Test

- **Criterion 7153 — completing a job generates its invoice:** At
  `/schedule/jobs/new`, create a job against the "836 Card St" property
  (today's date, any start/end time, price $150.00, no cleaner). Submit
  navigates to `/schedule/jobs/:id` — note the id. Visit
  `/field/jobs/:id`, click `[data-test='mark-complete-button']` ("Finish
  Job" — the seeded checklist is empty so there's nothing to gate on).
  Expect the header badge to read "Complete". Visit `/invoices` and
  confirm a new row for "QA Card Client 836" / $150.00 appears.
  Repeat against "837 NoCard Ave" at a lower price (e.g. $90.00) for use
  in the payment-link scenario below — both rows should be visible on
  `/invoices` afterward.
- **Criterion 7154 — auto-charge the card on file:** Open the invoice
  for QA Card Client 836. `[data-test='charge-card-button']` should be
  present (card on file, unpaid, no prior intent). Click it and record
  what actually happens — a move to "Charge Pending" status, or a flash
  error. This exercises the **real** `StripeGateway.Live` adapter
  (`config.exs` sets `adapter: Live` for every env except `:test`) — note
  the payment_method it submits is a synthetic placeholder string
  (`"card_on_file:<client-id>"`, see `CleanerCrm.Billing`'s own moduledoc
  comment on this), not a real Stripe token, so document the actual
  provider response rather than assuming success.
- **Criterion 7155 — client with no card on file pays via payment
  link:** Open the invoice for QA NoCard Client 836. Confirm NO
  `charge-card-button` renders (client has no card on file), but
  `[data-test='send-payment-link-button']` does (status unpaid). Click
  it, then read the `[data-test='payment-link']` anchor's `href` (a
  `/pay/:token` path). Via curl: `GET` that path and confirm it renders
  "Pay Invoice" and the correct amount; then `POST` it with
  `payment_method=pm_card_visa&save_card=true` and record the actual
  response — expected per spec is "Payment received" + a "save your
  card" mention, but this also goes through the real Stripe adapter, so
  confirm rather than assume.
- **Criterion 7156 — invoice shows the job's proof-of-work:** Open
  either seeded webhook-test invoice (DECLINE or SUCCESS — both carry
  identical proof-of-work). Confirm the "Proof of Work" section lists
  both checklist item task names (e.g. "Kitchen counters wiped down
  (decline)") and that at least one `[data-test='proof-of-work-photo']`
  `<img>` renders. Note: there is no in-app UI path today to populate a
  checklist with named tasks on a real job (see Setup Notes) — this
  criterion is only reachable via the seeded invoices, not the two
  jobs completed live in the 7153 scenario above (their checklists are
  empty).
- **Criterion 7157 — card-on-file charge is declined:** First, on the
  DECLINE test invoice's page, confirm its starting state is "Charge
  Pending" (no charge/retry button contradiction). Then `curl -X POST
  http://127.0.0.1:4100/webhooks/stripe` with header
  `Content-Type: application/json` and body
  `{"type":"payment_intent.payment_failed","data":{"object":{"id":"pi_qa_836_declined","metadata":{"invoice_id":"<DECLINE invoice uuid>"}}}}`.
  Record the HTTP status/body (the Live adapter's `verify_webhook_event`
  requires a valid `Stripe-Signature` header computed from
  `STRIPE_WEBHOOK_SECRET` — an unsigned curl payload may be rejected
  with 400 `invalid_signature`; this is itself worth confirming either
  way). If accepted, reload the invoice page and confirm status
  "Unpaid" plus both `[data-test='retry-charge-button']` and
  `[data-test='send-payment-link-button']`.
- **Criterion 7158 — invoice marked paid on provider confirmation:**
  Same curl pattern against the SUCCESS test invoice, with
  `"type":"payment_intent.succeeded"` and
  `"id":"pi_qa_836_succeeded"`/its invoice uuid. If accepted, reload the
  invoice page and confirm status "Paid", and that `/invoices` shows it
  settled as "Paid" in the billing queue.

## Result Path

`.code_my_spec/qa/836/` (screenshots in `.code_my_spec/qa/836/screenshots/`);
canonical result is the `submit_qa_result` DB attempt + linked issues.

## Setup Notes

`CleanerCrmWeb.FieldLive.Job.load_checklist/1` always instantiates a job's
checklist as `Quality.create_checklist(scope, job, [])` (empty) rather
than through `Quality.instantiate_checklist/3` against a
`ChecklistTemplate` — and no route/LiveView anywhere manages
`checklist_templates` or calls `instantiate_checklist/3` at all. In
practice this means a checklist created through the real product today
can never carry named tasks or photos, so criterion 7156 (proof-of-work
on the invoice) can only be demonstrated by seeding a checklist directly
(as `qa_seeds_836.exs` and the BDD fixtures both do), never by a real
owner/cleaner working a job end-to-end. Worth a filed issue regardless
of how the rest of the story's scenarios land.

Per the payments-stripe ADR (see `CleanerCrm.Billing` moduledoc), an
invoice's status only ever advances on a Stripe webhook confirmation —
clicking "charge card" or paying via link never marks an invoice paid
synchronously, only `:charge_pending`. Both the card-on-file charge and
the payment-link charge run through `CleanerCrm.Billing.StripeGateway.Live`
in this dev environment (only `config/test.exs` swaps in the in-memory
`Test` adapter) — real outbound HTTPS calls to `api.stripe.com` using
whatever `STRIPE_SECRET_KEY`/`STRIPE_WEBHOOK_SECRET` the running server
process was started with (not necessarily present in the tester's own
shell env — check with `.code_my_spec/qa/scripts/verify_stripe.sh` if
results look like a missing-credential failure rather than a declined
charge).
