# Qa Story Brief — 843 Get loud, acknowledged alerts when my schedule changes

## Tool

web

## Auth

Two sessions needed in the same browser (log in/out between phases as needed):
- Owner: `qa-owner@cleanercrm.test` / `qa password 1234` via `/users/log-in` (password form).
- Cleaner: `qa-cleaner@cleanercrm.test` / `qa password 1234`, same form.

## Seeds

Uses existing fixture jobs (both `scheduled`, today 2026-07-08, assigned to qa-cleaner, user id 2):
- Job A `7a048bd4-c474-4d50-a4bd-7e5bdc74f27d` — 836 Card St, 13:00-15:00. Used for the moved-job / acknowledge / push-fallback scenarios.
- Job B `dbd5a7b7-5390-423f-9fab-ca100cdcced8` — 475 QA841 Test Ave, 11:00-12:00. Used for the cancel / keeps-prompting / escalation scenarios.

Escalation window is 600s, computed lazily on every read (`CleanerCrm.Notifications.latest_schedule_change_for_job/2`) — no periodic job to wait for; pin `pushed_at` via psql to simulate elapsed time:
`psql -h localhost -d cleaner_crm_dev -c "update notifications set pushed_at = now() - interval '11 minutes' where job_id = 'dbd5a7b7-5390-423f-9fab-ca100cdcced8' and status = 'pending';"`

Push-fallback needs `push_enabled = false` on the cleaner (no UI toggle exists yet):
`psql -h localhost -d cleaner_crm_dev -c "update users set push_enabled = false where email = 'qa-cleaner@cleanercrm.test';"`
Revert after testing: `... set push_enabled = true where email = ...`.

## What To Test

- Owner on `/schedule`: change Job A's `[data-test='job-<id>-start-time-input']` to a new time → board's `[data-test='job-<id>-ack-status']` shows "Unacknowledged" and `[data-test='job-<id>-notification-channel']` shows "Push" + the new time.
- Cleaner on `/field`: sees `[data-test='schedule-alert']` with both old and new times in the message.
- Cleaner clicks `[data-test='schedule-alert-<id>-acknowledge-button']` → alert disappears; reload `/field` → still gone.
- Owner reloads `/schedule` → Job A's ack-status flips to "Acknowledged".
- Owner cancels Job B via `[data-test='job-<id>-cancel-button']` → cleaner's `/field` shows an alert containing "Cancelled".
- Without acknowledging, reload cleaner's `/field` again → the same alert is still present (unacknowledged change keeps prompting).
- Pin Job B's notification `pushed_at` 11 minutes back via the psql command above → owner reloads `/schedule` → Job B's ack-status shows "Escalated" and channel shows "SMS".
- Set `push_enabled=false` on qa-cleaner, reschedule Job A to a further new time → board's notification-channel for Job A shows "SMS" + the new time (push failure fallback). Revert `push_enabled` to true afterward.

## Result Path

No result.md — findings via `create_issue`, outcome via `submit_qa_result`.

## Setup Notes

`schedule_change_alert/2` reads the *latest* notification per job, so re-triggering a change on the same job (e.g. Job A twice) always reflects the newest one — expected, not a bug. Office routes are owner-only; cleaner routes are `/field*`.
