# Qa Story Brief

## Tool

web

## Auth

Login at http://127.0.0.1:4100/users/log-in (password form, second `<form>` on the
page, id `login_form_password` — the first form is magic-link and shares the same
`user[email]` field name, so scope selectors to `#login_form_password`).

- Owner: `qa-owner@cleanercrm.test` / `qa password 1234`
- Cleaner: `qa-cleaner@cleanercrm.test` / `qa password 1234`

Submit buttons are `button` elements with no stable selector other than text
("Log in and stay logged in →"); match by textContent rather than CSS.

## Seeds

Existing QA seed data plus jobs created/edited this pass, all cleaner
`qa-cleaner@cleanercrm.test` (user id 2):

- `48ae34be-eb88-489b-9bd5-331476a9307b` — edited to `pay_type=hourly`,
  `hourly_rate_cents=2000`; pre-existing resolved time entry (11.3s).
- `51ef260f-90db-4357-9403-ea3574f9bac2` — edited to `pay_type=piece_rate`,
  `piece_rate_cents=4500`; pre-existing resolved time entry spanning ~22.5h.
- `e604cc04-c345-4638-9476-cfdbab3c33a6` — new job, `pay_type=hourly`,
  `hourly_rate_cents=2500`, created via /schedule "New Job" with the new pay
  fields; clocked in, then resolved to a clock-out ~2.5h later via the
  owner's /timesheets resolve form.

## What To Test

- Cleaner clocks in/out of an assigned job (criterion 7121): /field/jobs/:id,
  `[data-test="clock-in-button"]` then `[data-test="clock-out-button"]`.
- Cleaner opens a job not assigned to them (criterion 7123): direct navigation
  to another cleaner's /field/jobs/:id redirects to /field with flash
  "This job is not assigned to you."; no time entry recorded.
- New/Edit job form at /schedule now has "Cleaner pay type" (hourly/piece
  rate) + a matching rate input (criteria 7125, 7128 setup).
- /timesheets: pay-period totals per job and per cleaner, resolve-clock-out
  form only shown for genuinely-open entries (a separate "Pay type not set
  for this job" message covers the other case), Export CSV
  enabled/disabled by unresolved state (criteria 7130, 7137, 7140).
- /timesheets/export?start_date=...&end_date=...: CSV download, one row per
  cleaner with hours/job_count/gross_pay (criterion 7134).

## Result Path

Findings filed via create_issue; outcome via submit_qa_result (this file is
not the canonical record).

## Setup Notes

Re-run after the dev team shipped pay-type/rate fields on the job form and
fixed the timesheet's open-entry-vs-no-pay-type conflation (previously filed
as issues a9233027 and e3d5222b). All 8 criteria now verified live:

- Hourly: job e604cc04 at $25/hr, resolved to a 2.4949h duration (13:37:18.2
  to 16:07:00) → $62.37, matching `round(2500 * 2.494942)` exactly.
- Piece rate: job 51ef260f at $45 flat paid regardless of its ~22.5h
  recorded time.
- Running total: cleaner's pay-period total went from $45.06 (2 resolved
  jobs) to $107.43 once the third job was resolved — exact sum of $0.06 +
  $45.00 + $62.37.
- Export blocked while e604cc04 was open (button disabled, warning shown);
  enabled immediately once resolved.
- CSV export (curl against `/timesheets/export`) returned
  `text/csv`, filename `payroll-2026-07-06-2026-07-12.csv`, and the row
  `qa-cleaner@cleanercrm.test,25.01,3,$107.43` — hours/job_count/gross_pay
  matching the UI and the underlying DB timestamps exactly.

Also hit an intermittent, unrelated environment issue mid-pass (a
`Protocol.UndefinedError` on `CleanerCrm.Quality.ChecklistTemplate` for one
specific job, and later a broader module-loading instability affecting `/`
and static assets) — reported to and resolved by the team lead (server now
runs as a compiled OTP release from a fixed path, not `_build`). Not a
product defect; no issue filed for it.
