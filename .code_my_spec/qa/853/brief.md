# Qa Story Brief

## Tool

web (FieldLive.Job to mark complete, ReviewLive.Public for the token-link review page, ReviewLive.Index for the owner inbox); psql for time-travel on job `updated_at` (sanctioned per the QA plan for this story's 24h-later scan) and for direct verification of `reviews` table rows.

## Auth

Owner: `qa-owner@cleanercrm.test` / `qa password 1234` at `/users/log-in` — used to mark a job complete at `/field/jobs/:id` (office staff can access any job, not just their own) and to view `/reviews`.

Review submission pages need no login — reached via the mailed token link `/reviews/:token`.

## Seeds

Base seeds already applied. Story-specific data created directly (no owner UI exists to seed review requests, since they're only ever created by `CleanerCrm.Reviews.ReviewRequestWorker`):

- Client "QA Review853 Client" (`be2ae016-c756-4db2-9bf4-37f91d5f1fb9`), job `11a07972-2669-493f-a9c0-e042764bdee3` — marked complete via the real `/field/jobs/:id` flow to test the thank-you (7244), then its `updated_at` backdated 25 hours via psql so the real Oban cron scan (runs every 15 minutes, `*/15 * * * *`, see `config/config.exs`) picks it up as due for the 24h-later review request (7245) on its own next tick, and a subsequent tick after that confirms no duplicate is sent (7246).
- Client "QA Incomplete853 Client" (`be950c98-f367-4845-9c2e-f35c4fce6591`), job `ad9d8056-9e07-44e3-a682-5bcbdf5ae3d3` — status `in_progress` (never completed), `updated_at` already 3 days old. Confirms the scan never fires for it (7250) — check via psql (`select * from reviews where job_id='ad9d8056-...'` should be empty) and the mailbox (no email to `qa-incomplete853@example.com`).
- Client "QA HighRating853 Client" + job `2dff2979-a89b-4b2b-a056-f3250aca18c6` + a `reviews` row seeded directly with `status='review_requested'`, token `qa853hightoken1234567890abcdef`. Use for criterion 7247.
- Client "QA LowRating853 Client" + job `b27fb47f-cb03-488e-bd12-78265578b86a` + a `reviews` row seeded directly with `status='review_requested'`, token `qa853lowtoken1234567890abcdefgh`. Use for criteria 7248 and 7249 (same submission, then check the owner inbox).

## What To Test

- **Thank-you sent on completion (7244):** already driven live — clicked `[data-test='mark-complete-button']` on job `11a07972-...`; verify `/dev/mailbox` shows a "Thank you..." email to `qa-review853@example.com` with subject matching /thank/i.
- **Review request sent ~24h later (7245):** after the backdated job's `updated_at` clears the next `*/15 * * * *` Oban tick, check `/dev/mailbox` for a new email to `qa-review853@example.com` with subject matching /review/i, and confirm via psql a `reviews` row now exists for job `11a07972-...` with `status='review_requested'` and a token.
- **No duplicate review request (7246):** after a SECOND cron tick passes following the first review request, confirm no second email arrives for the same client/job and the `reviews` row for that job is still exactly one row (`select count(*) from reviews where job_id='11a07972-...'` = 1).
- **High rating routes to publish (7247):** visit `/reviews/qa853hightoken1234567890abcdef`, click `[data-test='review-rating-5']`, submit `[data-test='review-form']` with `review[text]` filled in. Expect `[data-test='review-published-notice']`.
- **Low rating routes to private complaint (7248):** visit `/reviews/qa853lowtoken1234567890abcdefgh`, click `[data-test='review-rating-2']`, submit with a complaint in `review[text]`. Expect `[data-test='review-private-notice']`, and NOT `[data-test='review-published-notice']`.
- **Owner receives private complaint (7249):** after the low-rating submission above, log in as owner and visit `/reviews`. Expect `[data-test='review-row-971022b9-756d-4902-802a-c57a14b0f1c6']` showing the complaint text and `[data-test='review-971022b9-756d-4902-802a-c57a14b0f1c6-visibility']` reading "Private".
- **No review prompt for incomplete visit (7250):** confirmed by the same cron ticks used for 7245/7246 — job `ad9d8056-...` (in_progress) must never generate a `reviews` row or an email to `qa-incomplete853@example.com`, no matter how many ticks pass.
- Explore: submit the review form with no rating selected (expect a "select a rating first" flash, no crash); try re-submitting an already-submitted review token (should be a no-op, not double-recorded); try an invalid/unknown review token (expect `[data-test='review-invalid-notice']`, not a crash); mobile spot-check `/reviews/:token` at 390x844.

## Result Path

Findings are filed via `create_issue` as discovered; final record is the `submit_qa_result` DB attempt (task id `3dedf434-3322-4c74-aab4-7651e5451096`). Screenshots: `.code_my_spec/qa/853/screenshots/`.
