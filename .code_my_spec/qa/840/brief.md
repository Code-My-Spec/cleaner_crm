# Qa Story Brief

## Tool

web

## Auth

Login at http://127.0.0.1:4100/users/log-in, password form `#login_form_password`.
Owner: `qa-owner@cleanercrm.test` / `qa password 1234`. Only the account owner
can view /audit (non-owners are redirected with a flash) — but note
`/schedule` and `/timesheets` have no such gate (see Setup Notes, filed issue
f7ee0171).

## Seeds

Existing QA data plus:
- One recurring plan from /schedule/plans/new (property "12 Cedar Ct",
  weekly, start 2026-07-13, 3 visits) — plan id
  3da1ffbc-5289-4ec9-9d6f-65f73df73777, jobs 25c8c992/9f98d26b/572801c5, for
  system-attributed entries.
- Job `71182268-c79b-4afb-8a18-914e2e20a7f4` ("Jamie Rivera QA1"), edited
  via /schedule's Edit form: start/end time changed 09:00-11:00 →
  13:00-15:00, then price set nil → $120 → $140 in two separate saves.

## What To Test

- /audit as owner: entries render actor, action, subject, timestamp, field
  diffs. "System created ..." rows for the 3 plan-generated jobs (criterion
  7204).
- /schedule board "Edit" per job: change date/time → /audit shows
  `job_rescheduled` with old/new start_time+end_time (criterion 7193); change
  price only (separately) → `job_price_changed` with old/new
  agreed_price_cents only, no unrelated fields (criterion 7195).
- /audit filter form now has three selects/inputs: Subject ID, **Changed by**
  (every account member + "System"), **Record type** (Job/Property/Quote),
  plus From/To dates (criterion 7201). Filters combine with AND — filtering
  actor=qa-cleaner + type=Property correctly returns zero rows (qa-cleaner
  has only ever touched Job records).
- Append-only (criterion 7198): verified via code + migration inspection,
  not a live destructive attempt (see Setup Notes).

## Result Path

Findings filed via create_issue; outcome via submit_qa_result (this file is
not the canonical record).

## Setup Notes

Re-run after the dev team shipped "Changed by"/"Record type" filters on
/audit (previously filed as issue fb8da672, now resolved). All 5 criteria
verified live this pass:

- 7193: audit_entries row for job 71182268 shows
  `action=job_rescheduled`, `old_value={"end_time":"11:00:00","start_time":"09:00:00"}`,
  `new_value={"end_time":"15:00:00","start_time":"13:00:00"}`.
- 7195: two separate `job_price_changed` rows —
  `old_value={"agreed_price_cents":null}` → `new_value={"agreed_price_cents":12000}`,
  then `{"agreed_price_cents":12000}` → `{"agreed_price_cents":14000}` — no
  scheduled_date/start_time/end_time present in either, confirming only the
  changed field is captured. /audit renders these as "Price: — → $120.00" and
  "Price: $120.00 → $140.00".
- 7198: unchanged from prior pass — `Audit.Recorder` only ever inserts, no
  update/delete function exists anywhere, and the migration adds Postgres
  RULEs (`audit_entries_no_update`/`_no_delete`) that `DO INSTEAD NOTHING`.
- 7201: the new "Changed by" select lists every account member plus "System";
  selecting qa-cleaner narrowed the trail to exactly qa-cleaner's 4 entries.
  The new "Record type" select (Job/Property/Quote) combined with the actor
  filter correctly returned zero rows for actor=qa-cleaner + type=Property.
  Subject ID and date-range filters (already confirmed in the prior pass)
  still work alongside the new selects.
- 7204: unchanged from prior pass — the 3 plan-generated jobs show "System
  created ..." rather than a blank actor.

Also surfaced, while attempting to log in as owner for this pass: the
login page's reauthenticate flow silently re-authenticates whichever
account's session is still active (pre-filled/readonly email) rather than
prompting for a fresh account — I didn't notice and performed the reschedule
above as qa-cleaner, not owner, before catching it via `actor_id` in the DB.
That led to a separate, more serious finding: `/schedule` and `/timesheets`
have no owner/admin role check at all (unlike `/audit`, which does), so any
authenticated cleaner can reschedule/price-change/cancel/delete any job,
create recurring plans, and view/export the whole account's payroll. Filed
as issue f7ee0171 (critical) — directly relevant to this story's "hold my
office team accountable" premise, even though it isn't one of the 5 listed
acceptance criteria.
