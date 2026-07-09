# Qa Story Brief

## Tool

web

## Auth

Login at http://127.0.0.1:4100/users/log-in, password form `#login_form_password`
(the page renders a magic-link form first with the same field names — scope
selectors to the id).

- Owner: `qa-owner@cleanercrm.test` / `qa password 1234`
- Cleaner: `qa-cleaner@cleanercrm.test` / `qa password 1234`

## Seeds

Existing QA data had only 2 scored jobs total (both qa-cleaner, both pre-scored
5). No incomplete job existed with a real (multi-required-task) checklist
template, so this session created one via the owner's /schedule board "New
Job" button: property "836 Card St" (id 7d0490a1-cd58-47c4-bebf-1d1f9c047f08,
carries checklist_template 7144b919 with 2 required tasks + 1 optional),
date 2026-07-08, 13:00-15:00, assigned to qa-cleaner. Resulting job id
`bb40913a-e5b1-44f2-af4e-fa46520781d8`.

## What To Test

- /field/jobs/:id as qa-cleaner: click Finish Job with required tasks
  unchecked (criterion 7163) — expect blocked with a warning listing the
  unchecked required tasks.
- Check off required tasks, attach before/after photos via the file inputs
  scoped under `#checklist-item-<id> input[name="before_photo"/"after_photo"]`
  (criterion 7165) — expect "photo attached" + timestamp text.
- Click Finish Job again once all required tasks are checked (criterion
  7161) — expect job badge flips to "Complete".
- As owner, /quality/:job_id: verify checklist + timestamped photos display
  (criteria 7165, 7174), submit `quality-rating-form` with a 1-5 rating
  (criterion 7168) — expect `[data-test="quality-score"]` to change.
- As owner, /quality/scorecards, click `[data-test="scorecard-cleaner-<id>"]`
  (criterion 7171) — expect average score + trend across completed jobs.
- Criterion 7176 (offline photo upload): no network-throttling tool was
  available in this session; assessed by code review instead (see Setup
  Notes / filed issue).

## Result Path

Findings filed via create_issue; outcome via submit_qa_result (this file is
not the canonical record).

## Setup Notes

Three findings filed: skip-with-reason never captures or shows a real reason
(fc4b2fb6, high), a stale "still needed" banner that doesn't clear once
required tasks are checked off (36867267, medium, cosmetic — Finish Job still
succeeds), and no offline-tolerant photo capture path exists despite
`CleanerCrm.Quality.Photo`'s moduledoc describing exactly that design
(b14023ef, high, code-review finding — untestable live without network
throttling).
