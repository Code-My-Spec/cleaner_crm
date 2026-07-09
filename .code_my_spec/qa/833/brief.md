# Qa Story Brief

Story 833 — Schedule recurring cleaning plans with series-wide conflict detection

## Tool

web

## Auth

Log in via the browser at `http://127.0.0.1:4100/users/log-in`:
- Owner: `qa-owner@cleanercrm.test` / `qa password 1234`
- Password form fields: `input[name="user[email]"]`, `input[name="user[password]"]`. The password form is below the magic-link form on the page — scroll it into view before filling. Submit redirects to `/`.

All scenarios below run as the owner. No second user/role is required for this story.

## Seeds

Base seeds: `mix run priv/repo/qa_seeds.exs` (idempotent — creates the owner, cleaner user, and "QA Sparkle Cleaning Co" account). Already verified working during brief-writing.

Story-specific data (client, property, cleaners, time-off, jobs) is created live through the UI during each scenario per the steps below — there are no additional seed scripts for plans/jobs. Use fresh client/cleaner names per scenario if re-running to avoid confusing state left over from a prior run (property/cleaner records are not idempotent like the base seed).

## What To Test

Router paths confirmed in `lib/cleaner_crm_web/router.ex`: `/schedule`, `/schedule/plans/new`, `/schedule/plans/:id/edit`, `/schedule/jobs/new`, `/schedule/jobs/:id/assign`, `/schedule/jobs/:id`, `/schedule/cleaners/new`, `/schedule/cleaners/:id`, `/schedule/cleaners/:cleaner_id/time-off/new`, `/clients/new`, `/clients/:id/properties/new`. All under `:require_authenticated_user`, so use browser tools only (never curl+cookies).

Data-test selectors (from `PlanFormComponent` source and the BDD spex files):
- Client form at `/clients/new`: `[data-test='client-form']`, field `client[name]`.
- Property form at `/clients/:id/properties/new`: `[data-test='property-form']`, field `property[service_address]`.
- Cleaner form at `/schedule/cleaners/new`: `[data-test='cleaner-form']`, field `cleaner[name]`.
- Time-off form at `/schedule/cleaners/:id/time-off/new`: `[data-test='time-off-form']`, fields `time_off[date]` (YYYY-MM-DD), `time_off[all_day]` (checkbox).
- Job form at `/schedule/jobs/new`: `[data-test='job-form']`, fields `job[property_id]`, `job[cleaner_id]` (optional), `job[date]`, `job[start_time]`, `job[end_time]`.
- Assignment form at `/schedule/jobs/:id/assign`: `[data-test='assignment-form']`, field `assignment[cleaner_id]`.
- Plan form at `/schedule/plans/new`: `[data-test='plan-form']`, fields `plan[property_id]`, `plan[cleaner_id]`, `plan[recurrence]` (`weekly`/`biweekly`/`monthly`), `plan[start_date]`, `plan[occurrence_count]`. Conflicts render live (phx-change) as `[data-test="conflict-visit-N"]` divs with text "Visit N (...) has a scheduling conflict: ..." and an `[data-test="override-conflict-N"]` override button. Save button: `[data-test='save-plan-button']` (plain phx-click, not a submit — click it directly).
- Board at `/schedule`: text "N jobs scheduled", `[data-test="job-card"]` per job.
- Job show page `/schedule/jobs/:id`: `[data-test='job-cleaner']` shows assigned cleaner name.

Use dates at least 14 days out (`Date.utc_today() + 14`) so recurring series don't collide with "today" edge cases, matching the spex fixtures.

Scenarios (map 1:1 to acceptance criteria / BDD spex files):

1. **Weekly plan generates the full series** (criterion 7143). Create client "Jamie Rivera QA1" + property "12 Oak Lane", cleaner "Alex Morgan QA1". Go to `/schedule/plans/new`, fill property, cleaner, recurrence=weekly, start_date=today+14, occurrence_count=8. Click save. Visit `/schedule` and confirm "8 jobs scheduled" and 8 `[data-test="job-card"]` elements. Screenshot the board.
2. **Conflict on a later occurrence is detected** (criterion 7147). New client/property, cleaner "Alex Morgan QA2". Create a time-off block on that cleaner for the date of the 4th weekly visit (start_date + 21 days) via `/schedule/cleaners/:id/time-off/new` with `all_day=true`. Create the 8-week weekly plan with that cleaner preferred. After save, confirm `[data-test='conflict-visit-4']` is present and no `[data-test='conflict-visit-1']` exists (only 1 conflict total). Screenshot the conflict banner.
3. **Clean series saves without warnings** (criterion 7148). New client/property, cleaner "Alex Morgan QA3" with no time-off. Create the 8-week weekly plan. Confirm no conflict divs render and the board shows "8 jobs scheduled" with 8 job cards and no "conflict" text.
4. **Assign a cleaner within their available hours** (criterion 7149). New client/property, cleaner "Alex Morgan QA4". Create an unassigned job for a Tuesday 9am-11am (next Tuesday + 7 days, to stay clear of "today"). Go to `/schedule/jobs/:id/assign`, submit `assignment[cleaner_id]` = that cleaner. Confirm the job show page displays `[data-test='job-cleaner']` = "Alex Morgan QA4" and no "conflict" text anywhere.
5. **Block assignment during a time-off block** (criterion 7150). New client/property, cleaner "Alex Morgan QA5" with an all-day time-off block on next Friday+7 days. Create an unassigned job that same Friday, 10am-12pm. Submit the assignment form for that cleaner. Confirm the response shows both "conflict" and "unavailable" text, and that the job remains unassigned (revisit job show page).
6. **Block an overlapping double-booking** (criterion 7151). New client/property, cleaner "Alex Morgan QA6". Create a job 10am-12pm on a date 14 days out, assigned directly to the cleaner (via job form's `job[cleaner_id]` if supported, else assign via the assign screen first). Create a second unassigned job 11am-1pm the same day, same property. Submit the assignment form assigning the same cleaner to the second job. Confirm the response shows "overlap" text and the second job stays unassigned.
7. **Owner reviews conflicting dates before saving** (criterion 7152). New client/property, cleaner "Alex Morgan QA7". Create time-off blocks on both the 4th and 7th weekly visit dates (start_date+21, start_date+42) before opening the plan form. Fill the plan form (weekly, start_date, no occurrence_count yet or default), then change `occurrence_count` to 8 via a `phx-change` (fill/blur, don't submit). Confirm `[data-test='conflict-visit-4']` and `[data-test='conflict-visit-7']` render, both `[data-test='override-conflict-4']` / `[data-test='override-conflict-7']` buttons are present, and `[data-test='save-plan-button']` is still available (plan not yet saved). Optionally click one override button and confirm that conflict row disappears while the save button remains. Screenshot before and after override.

After scripted scenarios, explore freely: try an invalid/blank plan form submit, try biweekly/monthly recurrence, try assigning a cleaner to an already-conflicting slot without overriding, and check for any 500s or raw stack traces.

## Result Path

`.code_my_spec/qa/833/screenshots/` (evidence only — findings go through `create_issue`, outcome through `submit_qa_result`, no result.md file).
