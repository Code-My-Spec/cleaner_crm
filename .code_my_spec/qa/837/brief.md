# Qa Story Brief — 837: Send automated appointment reminders to clients

## Tool

web for `/reminders` (settings + delivery log) and `/schedule` (board);
curl for the public, unauthenticated `/reminders/confirm/:token`,
`/reminders/reschedule/:token`, and `/webhooks/twilio` routes (plain
GET/POST controller actions, no session — token is the only auth).

## Auth

- Login URL: `http://127.0.0.1:4100/users/log-in`. Use
  `#login_form_password_email` / `#login_form_password button[name='user[remember_me]']`
  (the plain `input[name="user[email]"]` selector hits the magic-link
  form first).
- Owner creds: `qa-owner@cleanercrm.test` / `qa password 1234`.
- The confirm/reschedule/webhook routes need no login at all — they're
  public, token-authenticated links a client reaches from their own
  reminder message.

## Seeds

1. `mix run priv/repo/qa_seeds.exs` (base owner/cleaner/account).
2. `mix run priv/repo/qa_seeds_837.exs` — creates, all with `client_id`
   set directly via `CleanerCrm.Scheduling.create_job/2` (bypassing
   `/schedule/jobs/new`, which per story 836's filed issue 410ef0c3
   never sets `client_id` — `ReminderScheduler.due_jobs/1` filters
   `where: not is_nil(j.client_id)`, so a real UI-created job is
   invisible to the scanner regardless):
   - **QA Email Reminder 837** (preferred_channel: email) + a job
     scheduled exactly 24h from seed time (the lead-time boundary)
   - **QA SMS Reminder 837** (preferred_channel: sms, phone set) + a
     job scheduled exactly 24h from seed time
   - **QA Confirm 837** + a scheduled job + a seeded `:sent` reminder
     notification (token printed) for the confirm-action test
   - **QA Reschedule 837** + a scheduled job + a seeded `:sent`
     reminder notification (token printed) for the reschedule-action test
   - **QA Undeliverable 837** (preferred_channel: sms, phone + email
     both set) + a scheduled job + a seeded `:sent` SMS reminder
     notification with `provider_message_id: "sms_test_undelivered_837"`
     for the Twilio-webhook fallback test

   Prints every client/job/notification id and token — use them
   directly rather than re-deriving from the UI.

## What To Test

- **Criterion 7183 — reminder fires at the configured lead time:**
  At `/reminders`, submit `[data-test='reminder-settings-form']` with
  `settings[lead_time_hours]=24` (matches the seed's 24h-out jobs).
  Then run the scan deterministically:
  `mix run -e "CleanerCrm.Notifications.send_due_reminders()"` (mirrors
  what Oban's cron calls in production — see
  `CleanerCrm.Notifications.ReminderScheduler` moduledoc; don't wait on
  Oban's actual cron timing in a QA session). Reload `/reminders` and
  confirm the delivery log (`[data-test='delivery-log']`) gained a row
  for QA Email Reminder 837's contact info with status "sent". Check
  `http://127.0.0.1:4100/dev/mailbox` for the delivered email.
- **Criterion 7185 — client who prefers SMS gets a text reminder:**
  After the same scan run, check the delivery log row for QA SMS
  Reminder 837 — expect channel "SMS", not "Email". This exercises the
  real `CleanerCrm.Notifications.Delivery.Twilio` adapter (config.exs
  sets it for every env except `:test`) — if `TWILIO_ACCOUNT_SID`/
  `TWILIO_AUTH_TOKEN`/`TWILIO_FROM_NUMBER` aren't valid for this server
  process, `send_sms/2` will fail and the scheduler's own fallback
  (`ReminderScheduler.send_reminder/1`) silently sends email instead —
  note whichever actually happens rather than assuming success.
- **Criterion 7186 — reminder includes confirm and reschedule
  actions:** Open the delivered email for QA Email Reminder 837 in
  `/dev/mailbox` and confirm its body contains both an `href="…confirm…"`
  link and an `href="…reschedule…"` link.
- **Criterion 7187 — client confirms the appointment:** `curl` the
  printed confirm token's URL: `GET /reminders/confirm/:token` for QA
  Confirm 837's notification. Expect an HTML 200 response containing
  "Confirmed". Then check `/schedule` (the board) and confirm the row
  for that job (`[data-test='job-<job-id>']`) shows "Confirmed".
- **Criterion 7188 — client requests a reschedule:** `curl GET
  /reminders/reschedule/:token` for QA Reschedule 837's notification.
  Expect 200 containing "Reschedule requested". Confirm the board's row
  for that job shows "Needs reschedule".
- **Criterion 7189 — SMS reminder is undeliverable and falls back to
  email:** `curl -X POST /webhooks/twilio` with
  `Content-Type: application/json` and body
  `{"MessageSid":"sms_test_undelivered_837","MessageStatus":"undelivered","ErrorCode":"30003"}`
  for QA Undeliverable 837's seeded notification. Expect `{"ok":true}`
  (the controller always 200s). Then check `/dev/mailbox` for a new
  reminder email to QA Undeliverable 837's address, and `/reminders`'s
  delivery log for a row showing that client's phone with a status
  containing "undeliver".

## Result Path

`.code_my_spec/qa/837/` (screenshots in `.code_my_spec/qa/837/screenshots/`);
canonical result is the `submit_qa_result` DB attempt + linked issues.

## Setup Notes

Per story 836's own filed issue (410ef0c3), jobs created through the
real `/schedule/jobs/new` form never get `client_id` set — only
`property_id`. `CleanerCrm.Notifications.ReminderScheduler.due_jobs/1`
filters `where: not is_nil(j.client_id)`, so this bug has a second,
more severe consequence for this story: **a job created the normal way
through the product is permanently invisible to the reminder scanner —
no reminder ever fires for it, silently, with no error anywhere.** Confirm
this directly if time allows: create one more job via `/schedule/jobs/new`
at the lead-time boundary, run the scan, and check it produced no
notification — expected to reproduce the gap and should be tied to the
same root cause rather than filed as a brand new one, though the
consequence (reminders entirely unreachable, not just a display
issue) may warrant flagging at higher severity under this story.

Twilio's webhook handler (`Notifications.handle_delivery_status/1`, used
by `/webhooks/twilio`) does not verify any request signature — unlike
Stripe's, a bare curl POST is expected to be accepted and processed.
