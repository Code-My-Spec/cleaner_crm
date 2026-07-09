defmodule CleanerCrm.Notifications.ReminderSchedulerTest do
  @moduledoc """
  Regression test for issue 009fb5de: before the fix, an unconfigured
  Twilio adapter raised a `KeyError` out of `Delivery.Twilio.send_sms/2`
  instead of returning `{:error, _}`. That exception propagated out of
  `send_reminder/1` — never hitting the `{:error, _} -> send_email_reminder/2`
  clause — so an SMS-preferred client never got the email fallback, and
  `scan_and_send/1`'s `Enum.each` aborted every other due job in the
  same scan.
  """

  use CleanerCrmTest.DataCase, async: false

  import Swoosh.TestAssertions

  alias CleanerCrm.{Accounts, ClientsFixtures, Notifications, Scheduling, UsersFixtures}
  alias CleanerCrm.Notifications.{Delivery, Notification, ReminderScheduler}
  alias CleanerCrm.Users.Scope

  setup do
    original_adapter = Application.get_env(:cleaner_crm, :sms_delivery_adapter)
    original_twilio_config = Application.get_env(:cleaner_crm, Delivery.Twilio, [])

    Application.put_env(:cleaner_crm, :sms_delivery_adapter, Delivery.Twilio)
    Application.put_env(:cleaner_crm, Delivery.Twilio, [])

    on_exit(fn ->
      Application.put_env(:cleaner_crm, :sms_delivery_adapter, original_adapter)
      Application.put_env(:cleaner_crm, Delivery.Twilio, original_twilio_config)
    end)

    :ok
  end

  test "an unconfigured Twilio adapter falls back to email instead of crashing the scan" do
    user = UsersFixtures.user_fixture()
    scope = Scope.for_user(user)
    {:ok, account} = Accounts.create_account(scope, %{name: "Sparkle Co"})
    scope = %{scope | active_account_id: account.id, active_account: account}

    client =
      ClientsFixtures.client_fixture(scope, %{
        name: "Jamie",
        email: "jamie-#{System.unique_integer([:positive])}@example.com",
        phone: "+15555550101",
        preferred_channel: :sms
      })

    start_at = DateTime.add(DateTime.utc_now(), 3600, :second)
    start_time = DateTime.to_time(start_at)

    {:ok, job} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        agreed_price: Decimal.new("150.00"),
        status: :scheduled,
        scheduled_date: DateTime.to_date(start_at),
        start_time: start_time,
        end_time: default_end_time(start_time)
      })

    {:ok, _settings} = Notifications.update_reminder_settings(scope, %{lead_time_hours: 24})

    ReminderScheduler.scan_and_send()

    assert_email_sent(to: client.email)

    assert %Notification{channel: :email, status: :sent} =
             CleanerCrm.Repo.get_by!(Notification, job_id: job.id)
  end

  defp default_end_time(start_time) do
    candidate = Time.add(start_time, 2 * 3600, :second)
    if Time.compare(candidate, start_time) == :gt, do: candidate, else: ~T[23:59:59]
  end
end
