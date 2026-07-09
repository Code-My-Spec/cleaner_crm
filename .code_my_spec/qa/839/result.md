# QA Result — Story 839 (re-verification pass)

## Status: partial

Blocked from full browser-driven verification: the `mcp__vibium__browser_*`
tool namespace was completely unavailable in this session (every call, e.g.
`browser_launch`, returned "No such tool available"). Filed as framework
issue 5509cf00-09a9-4574-9eae-7931b043e88b. Worked around by combining
source-code review of the actual fix commits with direct Postgres state
changes (simulating what each fixed handler persists) and `curl` fetches
(via `.code_my_spec/qa/scripts/authenticated_curl.sh`) of the resulting
server-rendered HTML against the live running app. This validates the
render/read path and the data model genuinely, and the code inspected is
the real, currently-deployed handler code (not hypothetical) — but it does
not literally observe a phx-click/phx-submit round trip or a live,
no-reload DOM push the way a browser session would.

## Scenarios (fixed items, focused re-verification)

- **Skip-with-reason captures and displays a real reason** — pass.
  `lib/cleaner_crm_web/live/field_live/checklist_component.ex` now renders
  a per-item inline `<form data-test="skip-reason-form-#{item.id}">` with a
  free-text `reason` input, submitted via `phx-submit="skip"` straight to
  `Quality.skip_checklist_item(scope, item, reason)` (no hardcoded string
  anywhere). Set job e604cc04's "Scrub tub" item to
  `skipped=true, skip_reason="Client kept the bathroom door locked for a
  plumbing repair, could not access the tub to scrub it"` via psql, then
  fetched `/quality/e604cc04-...` as qa-owner: the Review page rendered
  `data-test="skip-reason-31c11eae-..."` with `Reason: Client kept the
  bathroom door locked...` directly under the "Skipped" badge, matching
  `lib/cleaner_crm_web/live/quality_live/review.ex` line 55-58.

- **"Still needed" banner clears live once required tasks are handled** — pass
  (render logic verified; live-push transition itself not observed without a
  browser). Confirmed initial GET of `/field/jobs/e604cc04-...` showed
  `data-test="incomplete-required-tasks-warning"` listing "Wipe countertops"
  and "Scrub tub". After skipping "Scrub tub" (above) and checking off
  "Wipe countertops" (`checked=true` via psql), refetched the same page —
  the warning `<div>` was gone entirely (only `checklist-progress` "1 of 3"
  remained). `ChecklistComponent.update/2` now unconditionally recomputes
  `Quality.incomplete_required_items(checklist)` on every assign update
  (source confirmed, no more `assign_new` caching), so this same
  recomputation runs identically whether triggered by a `:checklist_changed`
  live push or a fresh page load.

- **Photo pending -> uploaded lifecycle with retry affordance** — pass.
  Inserted a `photos` row with `upload_state='pending'` for the "Vacuum
  carpet" item's before-photo (simulating a dropped upload after the
  LiveView component fully remounts, per the moduledoc's stated design).
  Refetched the job page: rendered
  `data-test="task-12c5120c-...-before-photo-retry"` with text "Upload
  interrupted — tap to retry", confirming `existing_pending_photo/2` finds
  the leftover row and the retry affordance shows. Then updated that same
  row to `upload_state='uploaded'` with a `storage_key` and refetched again:
  rendered `data-test="task-12c5120c-...-before-photo"` → "before photo
  attached" plus a timestamp span, confirming the full pending→uploaded
  render lifecycle. `checklist_item_component.ex` source confirms the write
  path creates the pending row on first progress callback and flips it via
  `Quality.complete_photo_upload/3` on `entry.done?` — this is a manual
  retry model (not true offline queueing), as documented and as scoped by
  the task.

## Spot checks of previously-passing scenarios (not re-tested exhaustively)

- `/quality/scorecards` (owner) still renders the cleaner list correctly
  (13 `scorecard-cleaner-<id>` links present) — no regression evident; this
  code path wasn't touched by the 3 fixes.
- Checklist/photo/timestamp render code (`existing_photo/2`,
  `photo_zone/1`) is unchanged apart from the pending-photo addition, so
  criterion 7165 (before/after photos with timestamps) continues to work
  via the same render path exercised above.

## Evidence

- `/private/tmp/claude-501/-Users-johndavenport-Documents-github-cleaner-crm/b82dc084-1093-4624-b490-31c68a31a4a8/scratchpad/job_before.html` — initial field job page, banner present
- `/private/tmp/claude-501/-Users-johndavenport-Documents-github-cleaner-crm/b82dc084-1093-4624-b490-31c68a31a4a8/scratchpad/review_after_skip.html` — owner review page showing real skip reason
- `/private/tmp/claude-501/-Users-johndavenport-Documents-github-cleaner-crm/b82dc084-1093-4624-b490-31c68a31a4a8/scratchpad/job_after_checkoff.html` — banner cleared after required tasks handled
- `/private/tmp/claude-501/-Users-johndavenport-Documents-github-cleaner-crm/b82dc084-1093-4624-b490-31c68a31a4a8/scratchpad/job_after_pending_photo.html` — retry affordance rendered
- `/private/tmp/claude-501/-Users-johndavenport-Documents-github-cleaner-crm/b82dc084-1093-4624-b490-31c68a31a4a8/scratchpad/job_after_uploaded_photo.html` — uploaded photo rendered with timestamp
- `/private/tmp/claude-501/-Users-johndavenport-Documents-github-cleaner-crm/b82dc084-1093-4624-b490-31c68a31a4a8/scratchpad/scorecards.html` — scorecards spot check

## Issues

- 5509cf00-09a9-4574-9eae-7931b043e88b (high, scope: framework) — Vibium
  MCP browser tools not registered in this QA session; blocked genuine
  click/form-submit/live-DOM-update verification of a LiveView-heavy
  story. No new app-scope defects found in this pass — the 3 previously
  filed app issues (fc4b2fb6, 36867267, b14023ef) all verified resolved
  as described above.

## Note on test data

This session modified job `e604cc04-c345-4638-9476-cfdbab3c33a6`'s
checklist state (one item checked, one skipped-with-reason) and added an
uploaded photo row, via direct psql, to exercise the render paths above
since the browser tool was unavailable to drive the UI naturally. Left
in place as it does not conflict with other seed data.
