# Qa Story Brief — 846 Keep the same cleaner on the same home

## Tool

web

## Auth

Owner: `qa-owner@cleanercrm.test` / `qa password 1234` via `/users/log-in` (password form). This entire story is owner/office-only.

## Seeds

Existing fixtures reused (account `b4ecfdf7-95d9-4fc0-884a-353d9db1c473`):
- Property `a2b12702-4ad9-497c-b170-44a023f2cc23` ("12 Oak Lane", client "Jamie Rivera QA4") — used for the preferred-cleaner plan.
- Property `b7e981c5-0785-416c-89b4-bbeb97407f94` ("12 Oak Lane", client "Jamie Rivera QA5") — used for the no-preference plan.
- Cleaners: Alex Morgan QA4 (id 10), qa-ben (id 5, email qa-ben-834@cleanercrm.test), Alex Morgan QA5 (id 11) — none have conflicting jobs in the first week of August 2026.

## What To Test

- `/schedule/plans/new`: create a plan for the QA4 property with `cleaner_id` = Alex Morgan QA4, `recurrence: weekly`, `start_date: 2026-08-01`, `occurrence_count: 3`, save via `[data-test='save-plan-button']`.
- On `/schedule`, confirm all 3 materialized visits appear under `[data-test='cleaner-column-10']` (Alex Morgan QA4) — covers both "preferred cleaner set" and "every generated visit pre-assigned", not just the first.
- Reassign the first of those 3 visits to qa-ben (id 5) via `[data-test='job-<id>-cleaner-select']` → visit moves to `[data-test='cleaner-column-5']`, and `[data-test='preferred-cleaner-warning']` appears.
- Confirm the other 2 visits are still under `[data-test='cleaner-column-10']` — substituting one visit doesn't touch the plan's preference or its other visits.
- Create a second plan for the QA5 property with **no** `cleaner_id` set, `occurrence_count: 1`. Assign its single visit to Alex Morgan QA5 (id 11) via the cleaner-select → visit reassigns successfully and `[data-test='preferred-cleaner-warning']` does **not** appear (no preference to deviate from).

## Result Path

No result.md — findings via `create_issue`, outcome via `submit_qa_result`.

## Setup Notes

`PlanFormComponent`'s Save button is a plain `phx-click`, not a form submit, and only takes the most recent `phx-change="validate"` payload — so the browser flow is: fill each field (each blurs/changes and fires `validate`), then click `[data-test='save-plan-button']`. `deviates_from_preferred_cleaner?/2` (ScheduleLive.Index) is what renders `preferred-cleaner-warning`, comparing the job's `recurring_plan_id`'s plan `cleaner_id` against the newly assigned cleaner.
