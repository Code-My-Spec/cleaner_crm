defmodule CleanerCrmTest.Journeys.ScheduleChaosTest do
  @moduledoc """
  Journey 3 (.code_my_spec/qa/journey_plan.md): reminders, reschedules,
  cancellations, and the audit trail that reconstructs all of it.
  Confirming/rescheduling/cancelling all happen through the real
  `/schedule` board; the escalation-window backdate is done directly
  through `Repo` here (this test's equivalent of the sanctioned psql
  step from manual QA — same idea, same effect, just against the
  sandboxed test DB instead of dev).
  """

  use CleanerCrmTest.FeatureCase, async: false

  alias CleanerCrm.Notifications

  @sessions 2

  feature "reminders, reschedule/cancel alerts, acknowledgment, escalation, and the audit trail",
          %{sessions: [owner_session, cleaner_session]} do
    %{owner_scope: scope, owner: owner, cleaner: cleaner, password: password} =
      account_with_owner_and_cleaner()

    client = client_fixture(scope, %{name: "Journey3 QA Client"})
    property = property_fixture(scope, client, %{service_address: "9 Chaos Ct"})

    today = Date.utc_today()

    reminder_job =
      job_fixture(scope, property, %{
        cleaner_id: cleaner.id,
        scheduled_date: today,
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00],
        agreed_price_cents: 8000
      })

    reminder_token = Notifications.generate_token()

    {:ok, _} =
      Notifications.create_notification(scope, %{
        job_id: reminder_job.id,
        cleaner_id: cleaner.id,
        kind: :reminder,
        channel: :email,
        status: :sent,
        token: reminder_token
      })

    reschedule_job =
      job_fixture(scope, property, %{
        cleaner_id: cleaner.id,
        scheduled_date: today,
        start_time: ~T[13:00:00],
        end_time: ~T[15:00:00],
        agreed_price_cents: 8000
      })

    cancel_job =
      job_fixture(scope, property, %{
        cleaner_id: cleaner.id,
        scheduled_date: today,
        start_time: ~T[17:00:00],
        end_time: ~T[19:00:00],
        agreed_price_cents: 8000
      })

    owner_session = log_in(owner_session, owner, password)

    # Step 1: confirm the reminder, verify "Confirmed" on the board.
    owner_session
    |> visit!("/reminders/confirm/#{reminder_token}")
    |> assert_has(css("body", text: "Confirmed"))
    |> visit!("/schedule")
    |> assert_has(job_row(reminder_job.id, "Confirmed"))

    # Step 2: reschedule a different job's start time via the board's
    # inline time input — the one control confirmed (during manual QA)
    # to actually push a schedule-change alert.
    owner_session
    |> set_field("[data-test='job-#{reschedule_job.id}-start-time-input']", "13:30:00")
    |> settle()
    |> assert_has(job_row(reschedule_job.id, "Unacknowledged"))
    |> assert_has(job_row(reschedule_job.id, "moved from"))

    # Step 3: the cleaner sees the loud alert on /field and
    # acknowledges it; the owner's board reflects the ack.
    cleaner_session = log_in(cleaner_session, cleaner, password)

    cleaner_session
    |> visit!("/field")
    |> assert_has(css("[data-test='schedule-alert']"))
    |> click(css("[data-test$='-acknowledge-button']"))
    |> settle()

    owner_session
    |> visit!("/schedule")
    |> assert_has(job_row(reschedule_job.id, "Acknowledged"))

    # Step 4: cancel a job — it stays visible with a Cancelled badge
    # and Unacknowledged status.
    owner_session
    |> click(css("[data-test='job-#{cancel_job.id}'] button", text: "Cancel"))
    |> settle()
    |> assert_has(css("[data-test='job-#{cancel_job.id}-cancelled-badge']"))
    |> assert_has(job_row(cancel_job.id, "Unacknowledged"))

    # Step 5: backdate the cancellation alert past the escalation
    # window (10 minutes, per CleanerCrm.Notifications) — verify it
    # flips to Escalated/SMS on next read.
    cancel_notification =
      Notifications.list_notifications(scope)
      |> Enum.find(&(&1.job_id == cancel_job.id and &1.kind == :schedule_change))

    {:ok, _} =
      cancel_notification
      |> Ecto.Changeset.change(pushed_at: DateTime.add(DateTime.utc_now(), -700, :second))
      |> CleanerCrm.Repo.update()

    owner_session
    |> visit!("/schedule")
    |> assert_has(job_row(cancel_job.id, "Escalated"))

    # Step 6: the audit trail reconstructs the reschedule and
    # cancellation, filtered by actor and record type. The actor
    # select's option value is the user's id, not their email (see
    # `actor_options/1` in audit_live.ex).
    owner_session
    |> visit!("/audit")
    |> set_field("#filter_actor", to_string(owner.id))
    |> set_field("#filter_subject_type", "Job")
    |> settle()
    |> assert_has(css("[data-test='audit-entries']", text: "rescheduled"))
    |> assert_has(css("[data-test='audit-entries']", text: "cancelled"))
  end

  defp job_row(job_id, text), do: css("[data-test='job-#{job_id}']", text: text)
end
