# Story 837 QA seed script — run with: mix run priv/repo/qa_seeds_837.exs
#
# Jobs here set client_id directly via Scheduling.create_job/2 (bypassing
# /schedule/jobs/new, which per story 836's filed issue never sets
# client_id — ReminderScheduler.due_jobs/1 filters on it, so a
# UI-created job is invisible to the scanner regardless of lead time).
#
# Not idempotent — safe to re-run, accumulates a few more QA rows.

alias CleanerCrm.{Accounts, Clients, Notifications, Scheduling, Users}
alias CleanerCrm.Users.Scope

owner = Users.get_user_by_email("qa-owner@cleanercrm.test") || raise "run qa_seeds.exs first"
owner_scope = Scope.for_user(owner)
[account | _] = Accounts.list_accounts(owner_scope)
scope = %{owner_scope | active_account_id: account.id, active_account: account}

due_at = DateTime.add(DateTime.utc_now(), 24 * 60 * 60, :second)
due_date = DateTime.to_date(due_at)
due_time = DateTime.to_time(due_at) |> Time.truncate(:second)

end_time =
  case Time.add(due_time, 2 * 3600, :second) do
    t when t > due_time -> t
    _ -> ~T[23:59:59]
  end

# --- 7183/7186: email reminder due at the lead-time boundary ---
{:ok, client_email} =
  Clients.create_client(scope, %{
    name: "QA Email Reminder 837",
    email: "qa-email-837@example.com",
    preferred_channel: :email
  })

{:ok, job_email} =
  Scheduling.create_job(scope, %{
    client_id: client_email.id,
    agreed_price: Decimal.new("100.00"),
    status: :scheduled,
    scheduled_date: due_date,
    start_time: due_time,
    end_time: end_time
  })

# --- 7185: SMS-preferring client, same lead-time boundary ---
{:ok, client_sms} =
  Clients.create_client(scope, %{
    name: "QA SMS Reminder 837",
    phone: "+15555550837",
    preferred_channel: :sms
  })

{:ok, job_sms} =
  Scheduling.create_job(scope, %{
    client_id: client_sms.id,
    agreed_price: Decimal.new("100.00"),
    status: :scheduled,
    scheduled_date: due_date,
    start_time: due_time,
    end_time: end_time
  })

# --- 7187: client to confirm ---
{:ok, client_confirm} =
  Clients.create_client(scope, %{name: "QA Confirm 837", email: "qa-confirm-837@example.com"})

{:ok, job_confirm} =
  Scheduling.create_job(scope, %{
    client_id: client_confirm.id,
    agreed_price: Decimal.new("100.00"),
    status: :scheduled,
    scheduled_date: Date.add(due_date, 1),
    start_time: due_time,
    end_time: end_time
  })

{:ok, notification_confirm} =
  Notifications.create_notification(scope, %{
    client_id: client_confirm.id,
    job_id: job_confirm.id,
    kind: :reminder,
    channel: :email,
    status: :sent,
    token: "qa_confirm_837_#{System.unique_integer([:positive])}"
  })

# --- 7188: client to reschedule ---
{:ok, client_reschedule} =
  Clients.create_client(scope, %{
    name: "QA Reschedule 837",
    email: "qa-reschedule-837@example.com"
  })

{:ok, job_reschedule} =
  Scheduling.create_job(scope, %{
    client_id: client_reschedule.id,
    agreed_price: Decimal.new("100.00"),
    status: :scheduled,
    scheduled_date: Date.add(due_date, 1),
    start_time: due_time,
    end_time: end_time
  })

{:ok, notification_reschedule} =
  Notifications.create_notification(scope, %{
    client_id: client_reschedule.id,
    job_id: job_reschedule.id,
    kind: :reminder,
    channel: :email,
    status: :sent,
    token: "qa_reschedule_837_#{System.unique_integer([:positive])}"
  })

# --- 7189: SMS undeliverable -> email fallback ---
{:ok, client_undeliverable} =
  Clients.create_client(scope, %{
    name: "QA Undeliverable 837",
    phone: "+15555550838",
    email: "qa-undeliverable-837@example.com",
    preferred_channel: :sms
  })

{:ok, job_undeliverable} =
  Scheduling.create_job(scope, %{
    client_id: client_undeliverable.id,
    agreed_price: Decimal.new("100.00"),
    status: :scheduled,
    scheduled_date: Date.add(due_date, 1),
    start_time: due_time,
    end_time: end_time
  })

{:ok, notification_undeliverable} =
  Notifications.create_notification(scope, %{
    client_id: client_undeliverable.id,
    job_id: job_undeliverable.id,
    kind: :reminder,
    channel: :sms,
    status: :sent,
    token: "qa_undeliverable_837_#{System.unique_integer([:positive])}",
    provider_message_id: "sms_test_undelivered_837"
  })

IO.puts("""

Story 837 QA seed complete.

  Lead-time boundary used: #{due_date} #{due_time} (24h from seed run)

  Email reminder job:  client #{client_email.id} / job #{job_email.id}
  SMS reminder job:     client #{client_sms.id} / job #{job_sms.id}

  Confirm job #{job_confirm.id} -> GET /reminders/confirm/#{notification_confirm.token}
  Reschedule job #{job_reschedule.id} -> GET /reminders/reschedule/#{notification_reschedule.token}
  Undeliverable job #{job_undeliverable.id} / notification #{notification_undeliverable.id}
    -> POST /webhooks/twilio {"MessageSid":"sms_test_undelivered_837","MessageStatus":"undelivered","ErrorCode":"30003"}
""")
