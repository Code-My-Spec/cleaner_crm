# Qa Story Brief — 842 Work each job from a room-by-room checklist with photo proof

## Tool

web

## Auth

Log in as the cleaner via the browser login form:
- Navigate to `http://127.0.0.1:4100/users/log-in`
- Fill `input[name="user[email]"]` = `qa-cleaner@cleanercrm.test`
- Fill `input[name="user[password]"]` = `qa password 1234`
- Submit the password form; success redirects to `/field`.

## Seeds

Base seeds already applied (`mix run priv/repo/qa_seeds.exs`). Story-specific fixture used:

- Job `e604cc04-c345-4638-9476-cfdbab3c33a6` (836 Card St, qa-cleaner) with checklist `773de3d5-200b-4dc3-b409-629bd609c741`:
  - Kitchen / "Wipe countertops" (required) — item `50153438-279a-48d2-af6f-619c75f30e55`
  - Bathroom / "Scrub tub" (required) — item `31c11eae-1e20-4e87-85c6-adffb4fb99d9`
  - Living Room / "Vacuum carpet" (optional) — item `12c5120c-eb75-4c34-9c96-9d5d74645c5a`
- Reset via psql to unchecked/unskipped state before this session; a `pending` (interrupted-upload) photo row was inserted via psql for the Living Room item's `before` slot to simulate an offline-dropped upload.
- Test image files at `/private/tmp/claude-501/-Users-johndavenport-Documents-github-cleaner-crm/b82dc084-1093-4624-b490-31c68a31a4a8/scratchpad/qa842/{before1,after1,retry_before}.png`.

## What To Test

- `/field/jobs/e604cc04-c345-4638-9476-cfdbab3c33a6` opens with checklist grouped by room (`checklist-room-Kitchen`, `checklist-room-Bathroom`, `checklist-room-Living Room`), progress `0 of 3`.
- No out-of-scope task text appears (checklist renders exactly the 3 seeded items, nothing else) — AC: out-of-scope task absent.
- Living Room before-photo zone shows the interrupted-upload retry affordance (`task-<id>-before-photo-retry`) from the pre-seeded pending row.
- Click "Finish Job" with nothing checked → blocked; `incomplete-required-tasks-warning` banner lists both required tasks.
- Check off "Wipe countertops" → progress advances to `1 of 3`; banner narrows to just "Scrub tub".
- Attach before + after photos to "Wipe countertops" (real file uploads) → both show `task-<id>-before-photo` / `-after-photo` with timestamp.
- Check off "Scrub tub" → progress `2 of 3`; banner clears live (no re-click of Finish Job needed).
- Use the retry affordance on the Living Room item to complete the interrupted upload with a real file → pending state clears, before-photo shows attached.
- Click "Finish Job" again (Vacuum carpet still optional/unchecked) → job completes; verify via psql that `checklists.completed_at` and `jobs.status = 'completed'` are set.

## Result Path

No result.md — findings via `create_issue`, outcome via `submit_qa_result`.

## Setup Notes

Office/owner routes are out of scope for this story; all testing is under the cleaner's `/field` session. `psql -h localhost -d cleaner_crm_dev` used for fixture reset and DB verification.
