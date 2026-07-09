# Qa Story Brief

## Tool

web (portal LiveViews behind the magic-link session; owner/cleaner checks behind normal user login).

## Auth

Portal (no password): `http://127.0.0.1:4100/portal/access/qa851rescheduletoken1234567890ab` — client "QA Reschedule851 Client".

Owner: `qa-owner@cleanercrm.test` / `qa password 1234` at `/users/log-in` (password form, scroll `#login_form_password` into view first).

Cleaner (for the notification check): `qa-cleaner@cleanercrm.test` / `qa password 1234`, same login form. This cleaner is pre-assigned to the reschedule-test job.

## Seeds

Base seeds already applied. Story-specific data inserted directly (no owner UI exists yet for cancellation policy, mirroring the rate-card situation from story 848):

- Cancellation policy for the QA account: 48-hour notice window, $25 late fee, $50 same-day fee (`cancellation_policies` row, account `b4ecfdf7-95d9-4fc0-884a-353d9db1c473`).
- Client "QA Reschedule851 Client" (`7312486a-69ff-486a-8c12-4ba93824c57b`) with four jobs:
  - `bbde8f4e-2823-46ce-ad81-6683882957b3` — 7 days out, 10:00-12:00, cleaner `qa-cleaner@cleanercrm.test` assigned, $150.00 agreed price. Use for reschedule + price/scope-preserved + notify-office/cleaner (criteria 7222, 7225, 7226 — same action, three assertions).
  - `a875298b-b33f-4485-815a-806df49704e0` — tomorrow, 18:00-20:00, $80.00, unassigned. Inside the 48h notice window but not same-day -> late fee ($25) applies. Use for criterion 7223.
  - `49b62a20-8b93-4eb6-8f64-7f6e65e42d1a` — 5 days out, 10:00-12:00, $80.00. Outside the notice window -> no fee. Use for criterion 7224.
  - `268257e2-6262-40e0-bcf2-fb7c475cd79c` — today, 23:30-23:59, $80.00. Same-day -> maximum fee ($50) applies regardless of hours remaining. Use for criterion 7229.
- Completed visit already available for criterion 7227: job `e604cc04-c345-4638-9476-cfdbab3c33a6` (client "QA Card Client 836", portal token `qa850validtoken1234567890abcdefg` from story 850's QA session).

## What To Test

- **Reschedule from portal (7222):** open `/portal/visits/bbde8f4e-2823-46ce-ad81-6683882957b3`, submit `[data-test='reschedule-form']` with a new date (10 days out) and start time `14:00`. Expect the page to now show "2:00 PM" for the visit.
- **Reschedule preserves price and scope (7226):** on that same visit after rescheduling, confirm `[data-test='visit-price']` still reads $150.00 and `[data-test='visit-cleaner-name']` still shows the cleaner's identity — nothing but date/time should change.
- **Reschedule notifies office and cleaner (7225):** log in as `qa-cleaner@cleanercrm.test`, visit `/field`, expect a `[data-test='schedule-alert']` mentioning the visit's old/new time. Then log in as owner, visit `/schedule`, find this job's card and expect `[data-test='job-bbde8f4e...-ack-status']` (or equivalent) reading "Unacknowledged".
- **Late cancellation shows fee before confirming (7223):** open `/portal/visits/a875298b-b33f-4485-815a-806df49704e0`, click `[data-test='cancel-visit-button']`. Expect `[data-test='cancellation-fee-notice']` showing "$25.00" and a `[data-test='confirm-cancel-button']` — nothing charged yet.
- **On-time cancellation has no fee (7224):** open `/portal/visits/49b62a20-8b93-4eb6-8f64-7f6e65e42d1a`, click cancel — expect NO `[data-test='cancellation-fee-notice']`. Confirm the cancellation — expect the visit shows "Cancelled" status and no fee text anywhere.
- **Same-day cancellation charges maximum fee (7229):** open `/portal/visits/268257e2-6262-40e0-bcf2-fb7c475cd79c`, click cancel — expect `[data-test='cancellation-fee-notice']` showing "$50.00". Confirm — expect `[data-test='cancellation-fee-charged']` showing "$50.00".
- **Cannot modify a completed visit (7227):** open the completed job's portal detail (`/portal/visits/e604cc04-c345-4638-9476-cfdbab3c33a6` under the story-850 portal session `qa850validtoken1234567890abcdefg`) — expect NO `[data-test='reschedule-form']` and NO `[data-test='cancel-visit-button']`.
- Explore: try rescheduling to a past date via the reschedule form — expect a validation error, not a silently-accepted past visit (story 849's issue 4e985412 fixed the booking-acceptance side of this; verify the portal-side reschedule has the same guard). Try cancelling an already-cancelled visit a second time. Try accessing another client's visit id from this session (already covered generally in story 850, but re-spot-check here since visit mutation, not just viewing, is now in scope — confirm a cross-client reschedule/cancel attempt is blocked, not just blocked for viewing).

## Result Path

Findings are filed via `create_issue` as discovered; final record is the `submit_qa_result` DB attempt (task id `2a1172ec-7014-4c41-a4ec-513bf41dbda2`). Screenshots: `.code_my_spec/qa/851/screenshots/`.
