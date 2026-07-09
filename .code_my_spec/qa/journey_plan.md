# QA Journey Plan — Cleaner CRM

End-to-end journeys crossing story boundaries, from an owner setting up work
through a cleaner delivering it and the office getting paid. Each journey is
executable against the seeded dev instance in one sitting.

## Journeys

### Journey 1: New client to paid invoice

- **Role:** Cleaning business owner (with a cleaner assist for job completion)
- **Steps:**
  1. As owner, create a client (card on file) at /clients/new.
  2. Add a property with full access details (address, parking, lockbox code, pet notes) on the client page.
  3. Create a room-by-room checklist template for that property at /quality/templates/new.
  4. Build and send a per-room quote for the client at /quotes/new.
  5. Create a job for today on that property at /schedule/jobs/new, assigned to the cleaner, hourly pay type set.
  6. As cleaner, open the job at /field/jobs/:id, complete every checklist task with an after photo, and finish the job.
  7. As owner, open the generated invoice at /invoices, confirm client name + proof-of-work, charge the card on file.
  8. Simulate the provider confirmation (POST /webhooks/stripe payment_intent.succeeded) and confirm the invoice shows Paid.
- **Expected outcome:** One continuous data thread — client → property → template → quote → job → checklist proof → invoice — ends with a Paid invoice showing proof-of-work; audit trail shows the price-bearing changes.

### Journey 2: A day in the life of a cleaner

- **Role:** Cleaner
- **Steps:**
  1. Log in as the cleaner and open /field: today's jobs listed in start-time order, only own jobs visible.
  2. Open the first job: full get-in-the-door brief (address, parking, entry code visible day-of, pet notes).
  3. Clock in. Verify elapsed time starts.
  4. Work the room-by-room checklist; attach a before/after photo on at least one task.
  5. File an unsafe-condition incident report (no photo required) from the job screen.
  6. Clock out, complete the job, and check per-job earnings plus the pay-period running total on /field.
  7. Attempt to open another cleaner's job by URL — expect redirect to /field with "not assigned".
  8. Attempt to open /schedule and /timesheets — expect redirect to /field (office-only).
- **Expected outcome:** The cleaner completes a full working day entirely inside /field, with correct pay math, a filed incident visible to the office, and no access to office surfaces.

### Journey 3: Schedule chaos — reminders, changes, acknowledgment, audit

- **Role:** Cleaning business owner (office), with cleaner acknowledgment
- **Steps:**
  1. As owner, confirm a reminder-bearing job's confirm link (GET /reminders/confirm/:token) and verify "Confirmed" on the board.
  2. Reschedule a different job's start time from the board — verify the change is pushed as a schedule-change alert.
  3. As cleaner, see the loud alert on /field and acknowledge it; as owner, verify ack status on the board.
  4. Cancel a job on the board — verify it stays visible with a Cancelled badge and Unacknowledged status.
  5. Backdate the cancelled job's alert past the escalation window (psql) — verify status flips to Escalated / SMS.
  6. Open /audit and use the Changed by / Record type filters to locate the reschedule and cancellation entries ("Field: old → new").
- **Expected outcome:** Every schedule mutation reaches the affected cleaner loudly, unacknowledged changes escalate (even for cancelled jobs), and the audit trail reconstructs who changed what.

### Journey 4: Preferred cleaner continuity

- **Role:** Cleaning business owner
- **Steps:**
  1. Create a recurring weekly plan at /schedule/plans/new with a preferred cleaner set.
  2. Verify the materialized visits on the board default to the preferred cleaner.
  3. Reassign a single visit to another cleaner — expect the preferred-cleaner warning.
  4. Verify the plan's later visits still default to the preferred cleaner (substitution didn't change the plan).
  5. Create a second plan with no preference — verify reassignment produces no warning.
- **Expected outcome:** Clients keep their usual cleaner by default; one-off substitutions warn but don't rewrite the plan.

### Journey 5: Payroll close

- **Role:** Cleaning business owner
- **Steps:**
  1. Ensure the period has a mix of hourly and piece-rate completed jobs with resolved time entries (from Journeys 1–2 plus seeds).
  2. Open /timesheets: verify per-cleaner totals (hourly = rate × hours; piece-rate flat) and the running pay-period total.
  3. Introduce a forgotten clock-out (psql: null the clock-out on one entry) — verify the entry is flagged and export is blocked.
  4. Resolve the missing clock-out via the timesheet form — verify pay computes and export unblocks.
  5. Export the CSV (GET /timesheets/export via authenticated_curl.sh) and cross-check a row against the on-screen totals.
- **Expected outcome:** Payroll can be closed end-to-end with correct math, and unresolved time entries block the export until an owner resolves them.

## Prerequisites

- App running as the detached release: `PHX_SERVER=true /tmp/cleaner_crm_release/bin/cleaner_crm start` (already running at http://127.0.0.1:4100; never run mix against the dev env while it serves).
- Seeds: `mix run priv/repo/qa_seeds.exs` (idempotent) — owner qa-owner@cleanercrm.test / "qa password 1234", cleaner qa-cleaner@cleanercrm.test / same (account member), account "QA Sparkle Cleaning Co".
- Optional story-specific seeds: `mix run priv/repo/qa_seeds_837.exs` for reminder tokens.
- Stripe uses the Test adapter in dev; /webhooks/stripe accepts unsigned payloads; Twilio is unconfigured (SMS falls back to email by design).
- psql access to cleaner_crm_dev for persistence checks and time manipulation (escalation windows).
- Vibium browser is a single shared instance — one driver at a time.

## Notes

Journeys assume the post-QA hardened build: office surfaces are owner/admin-only,
confirm dialogs are DaisyUI modals ([data-role='confirm-confirm']), and all
phx-change controls are form-wrapped. Journey 3 step 5 manipulates time via
psql because the escalation window is computed from pushed_at; this is the
sanctioned approach used in story 843's QA.
