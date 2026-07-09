# Qa Story Brief — 844 Clock in/out per job and see my earnings build

## Tool

web

## Auth

Cleaner: `qa-cleaner@cleanercrm.test` / `qa password 1234` via `/users/log-in` (password form). One scenario also needs the owner session (`qa-owner@cleanercrm.test`, same password) only to confirm a different cleaner's job id; no owner-side UI assertions are required for this story.

## Seeds

Existing/added fixtures, all under account `QA Sparkle Cleaning Co` (`b4ecfdf7-95d9-4fc0-884a-353d9db1c473`), cleaner qa-cleaner (user id 2):

- Job `7a048bd4-c474-4d50-a4bd-7e5bdc74f27d` — piece-rate, `$80.00` (`piece_rate_cents: 8000`), scheduled today, not yet clocked in. Used for the piece-rate-up-front and first clock-in/out scenarios.
- Job `e86bcd8d-2ce3-4070-a212-24446c9be6bb` — second job assigned to qa-cleaner (scheduled 2026-07-15), used as the "next job" for the already-clocked-in-elsewhere and clock-out-then-clock-in scenarios.
- Job `0d5fd401-dd4e-4da6-8d01-82c4c26b3ef7` — assigned to a different cleaner (user id 3), used for the not-my-job redirect test.
- Job `ec8337a9-12f8-4124-afb1-c8a99b229449` — freshly created hourly job (`hourly_rate_cents: 2500`) with an already-open time entry clocked in 2 hours ago (`clocked_in_at: now() - 2h`), used for the hourly-earnings-on-clock-out scenario.

## What To Test

- `/field/jobs/7a048bd4-...` before clocking in: shows `$80.00` and no "/hr" or "per hour" text (piece-rate up front).
- Tap `[data-test='clock-in-button']` → "Clocked in" text and `[data-test='elapsed-time']` appear.
- Open `/field/jobs/e86bcd8d-...` (still clocked in on the first job) and tap Clock In → warned it's still clocked in to the first job's client, must clock out there first; no `[data-test='elapsed-time']` appears on this second job.
- Go back to `/field/jobs/7a048bd4-...` and tap `[data-test='clock-out-button']` → "Clocked out", `[data-test='worked-time']`, and job-earnings still `$80.00` (piece rate, time-independent).
- Now open `/field/jobs/e86bcd8d-...` and tap Clock In → succeeds this time: "Clocked in" + elapsed-time.
- Attempt to open `/field/jobs/0d5fd401-...` (someone else's job) as qa-cleaner → redirected to `/field` with an error flash containing "not assigned"; never renders the job page.
- Open `/field/jobs/ec8337a9-...` (2 hours already clocked, hourly $25/hr) and tap Clock Out → shows `$50.00` job earnings.
- On `/field`, note the pay-period total before/after these clock-outs — it should grow by the resolved amounts ($80 piece-rate + $50 hourly = $130) once both time entries are resolved.
- `/field`'s earnings card shows `[data-test='drive-time-policy']` stating drive time is unpaid (account's `drive_time_policy: :unpaid`).

## Result Path

No result.md — findings via `create_issue`, outcome via `submit_qa_result`.

## Setup Notes

`CleanerCrm.TimeTracking.current_pay_period/1` derives the pay period from the account-wide max `clocked_in_at`, not from `Date.utc_today()` directly — since all seeded and live-driven entries are today (2026-07-08), this stays consistent. `list_job_time_summaries/2` only counts jobs that have at least one time_entry row, even for piece-rate jobs, so every scenario here drives a real clock-in/out rather than relying on job.status alone.
