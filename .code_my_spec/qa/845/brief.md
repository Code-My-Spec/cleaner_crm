# Qa Story Brief — 845 Report damage, missing items, or unsafe conditions from the job

## Tool

web

## Auth

Cleaner: `qa-cleaner@cleanercrm.test` / `qa password 1234` via `/users/log-in` (password form).
Owner: `qa-owner@cleanercrm.test` / same password, to review at `/quality`.

## Seeds

Job `e86bcd8d-2ce3-4070-a212-24446c9be6bb` (client "QA Card Client 836", scheduled, assigned to qa-cleaner) is used for all incident-report scenarios. Test photo files created under the scratchpad (`before1.png`-style small PNGs) reused for upload.

## What To Test

- On `/field/jobs/e86bcd8d-...`, submit `[data-test='incident-report-form']` with `type: damage` and a description but **no** photo attached → blocked; response mentions "photo"; no `[data-test='incident-report-item']` appears.
- Attach a photo via `[data-test='incident-photo-upload']`, then submit the same damage report → succeeds; a `[data-test='incident-report-item']` appears with the description, `[data-test='incident-report-cleaner']` = qa-cleaner's email, and `[data-test='incident-report-timestamp']`.
- Submit an `unsafe_condition` report with a description and **no** photo → succeeds without any photo requirement.
- Reload the job page → both reports still present; no `[data-test='incident-report-edit-button']` or `[data-test='incident-report-delete-button']` anywhere.
- As owner on `/quality`, confirm `[data-test='incident-notification']` shows a count, both filed reports appear with matching cleaner/timestamp/client name, and no edit/delete affordances exist there either.
- File a `missing_item` report with a photo, then confirm on `/quality` that the notification/list identifies both the client and the description.

## Result Path

No result.md — findings via `create_issue`, outcome via `submit_qa_result`.

## Setup Notes

`IncidentFormComponent` renders on every `/field/jobs/:id` page regardless of job status; `QualityLive.Review` (`/quality`, owner-only) lists every incident report account-wide with no read/unread distinction — "office notified" is satisfied by that list + the `incident-notification` count banner always reflecting the current total.
