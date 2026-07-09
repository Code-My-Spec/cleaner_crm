defmodule CleanerCrm.PortalTest do
  use CleanerCrmTest.DataCase, async: true

  alias CleanerCrm.Accounts
  alias CleanerCrm.Billing
  alias CleanerCrm.Clients
  alias CleanerCrm.Portal
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Users.Scope

  import CleanerCrm.UsersFixtures

  setup do
    owner = user_fixture()
    owner_scope = Scope.for_user(owner)
    {:ok, account} = Accounts.create_account(owner_scope, %{name: "Sparkle Co"})
    scope = %{owner_scope | active_account_id: account.id, active_account: account}

    {:ok, client} = Clients.create_client(scope, %{name: "A Client"})

    %{scope: scope, account: account, client: client}
  end

  defp job_fixture(scope, client, attrs) do
    {:ok, job} =
      Scheduling.create_job(
        scope,
        Enum.into(attrs, %{
          client_id: client.id,
          scheduled_date: Date.add(Date.utc_today(), 7),
          start_time: ~T[09:00:00],
          end_time: ~T[11:00:00],
          status: :scheduled
        })
      )

    job
  end

  describe "create_portal_session/2 and access_portal/1" do
    test "a fresh token grants access to the client that issued it", %{client: client} do
      {:ok, session} = Portal.create_portal_session(client, %{})

      assert {:ok, client_id} = Portal.access_portal(session.token)
      assert client_id == client.id
    end
  end

  describe "access_portal/1 failure paths" do
    test "an expired session is refused", %{client: client} do
      {:ok, session} =
        Portal.create_portal_session(client, %{
          expires_at: DateTime.add(DateTime.utc_now(), -3600, :second)
        })

      assert {:error, :invalid} = Portal.access_portal(session.token)
    end

    test "an unknown token is refused" do
      assert {:error, :invalid} = Portal.access_portal("not-a-real-token")
    end
  end

  describe "list_upcoming_visits/1 and list_visit_history/1" do
    test "upcoming visits excludes completed and cancelled jobs", %{scope: scope, client: client} do
      upcoming = job_fixture(scope, client, %{})
      completed = job_fixture(scope, client, %{status: :completed})
      {:ok, cancelled} = Scheduling.cancel_job(scope, job_fixture(scope, client, %{}))

      visits = Portal.list_upcoming_visits(client)

      assert Enum.map(visits, & &1.id) == [upcoming.id]
      refute Enum.any?(visits, &(&1.id == completed.id))
      refute Enum.any?(visits, &(&1.id == cancelled.id))
    end

    test "visit history only includes completed jobs", %{scope: scope, client: client} do
      job_fixture(scope, client, %{})
      completed = job_fixture(scope, client, %{status: :completed})

      history = Portal.list_visit_history(client)

      assert Enum.map(history, & &1.id) == [completed.id]
    end
  end

  describe "get_visit!/2" do
    test "fetches a visit belonging to the client", %{scope: scope, client: client} do
      job = job_fixture(scope, client, %{})

      assert Portal.get_visit!(client, job.id).id == job.id
    end

    test "raises when the job belongs to a different client", %{scope: scope, client: client} do
      {:ok, other_client} = Clients.create_client(scope, %{name: "Someone Else"})
      job = job_fixture(scope, other_client, %{})

      assert_raise Ecto.NoResultsError, fn -> Portal.get_visit!(client, job.id) end
    end
  end

  describe "reschedule_visit/3" do
    test "moves the date/time while preserving price and cleaner", %{
      scope: scope,
      account: account,
      client: client
    } do
      cleaner = CleanerCrm.SchedulingFixtures.cleaner_fixture(scope, account)

      job =
        job_fixture(scope, client, %{
          cleaner_id: cleaner.id,
          agreed_price_cents: 15_000,
          start_time: ~T[10:00:00],
          end_time: ~T[12:00:00]
        })

      new_date = Date.add(Date.utc_today(), 10)

      assert {:ok, updated} =
               Portal.reschedule_visit(client, job, %{
                 "date" => Date.to_iso8601(new_date),
                 "start_time" => "14:00"
               })

      assert updated.scheduled_date == new_date
      assert updated.start_time == ~T[14:00:00]
      assert updated.end_time == ~T[16:00:00]
      assert updated.agreed_price_cents == 15_000
      assert updated.cleaner_id == cleaner.id
    end

    test "refuses to reschedule a completed visit", %{scope: scope, client: client} do
      job = job_fixture(scope, client, %{status: :completed})

      assert {:error, :not_modifiable} =
               Portal.reschedule_visit(client, job, %{
                 "date" => Date.to_iso8601(Date.add(Date.utc_today(), 10)),
                 "start_time" => "14:00"
               })
    end

    test "refuses to reschedule to a date already in the past", %{scope: scope, client: client} do
      job = job_fixture(scope, client, %{})

      assert {:error, :slot_in_past} =
               Portal.reschedule_visit(client, job, %{
                 "date" => "2020-01-01",
                 "start_time" => "14:00"
               })

      unchanged = Portal.get_visit!(client, job.id)
      assert unchanged.scheduled_date == job.scheduled_date
      assert unchanged.start_time == job.start_time
    end

    test "refuses to reschedule to today once the chosen start time has already passed", %{
      scope: scope,
      client: client
    } do
      job = job_fixture(scope, client, %{})
      now = DateTime.new!(Date.utc_today(), ~T[15:00:00], "Etc/UTC")

      assert {:error, :slot_in_past} =
               Portal.reschedule_visit(
                 client,
                 job,
                 %{"date" => Date.to_iso8601(Date.utc_today()), "start_time" => "14:00"},
                 now
               )
    end

    test "allows rescheduling to later today when the start time is still ahead of now", %{
      scope: scope,
      client: client
    } do
      job = job_fixture(scope, client, %{})
      now = DateTime.new!(Date.utc_today(), ~T[10:00:00], "Etc/UTC")

      assert {:ok, updated} =
               Portal.reschedule_visit(
                 client,
                 job,
                 %{"date" => Date.to_iso8601(Date.utc_today()), "start_time" => "14:00"},
                 now
               )

      assert updated.scheduled_date == Date.utc_today()
      assert updated.start_time == ~T[14:00:00]
    end
  end

  describe "cancellation_fee_cents/2 and cancel_visit/2" do
    setup %{scope: scope} do
      {:ok, _policy} =
        Portal.set_cancellation_policy(scope, %{
          notice_window_hours: 48,
          late_fee_cents: 2_500,
          same_day_fee_cents: 5_000
        })

      :ok
    end

    test "no fee outside the notice window", %{scope: scope, client: client} do
      job = job_fixture(scope, client, %{scheduled_date: Date.add(Date.utc_today(), 5)})
      assert Portal.cancellation_fee_cents(client, job) == 0
    end

    test "the late fee inside the notice window", %{scope: scope, client: client} do
      job =
        job_fixture(scope, client, %{
          scheduled_date: Date.add(Date.utc_today(), 1),
          start_time: ~T[10:00:00],
          end_time: ~T[12:00:00]
        })

      assert Portal.cancellation_fee_cents(client, job) == 2_500
    end

    test "the maximum fee for a same-day cancellation", %{scope: scope, client: client} do
      job =
        job_fixture(scope, client, %{
          scheduled_date: Date.utc_today(),
          start_time: ~T[18:00:00],
          end_time: ~T[20:00:00]
        })

      assert Portal.cancellation_fee_cents(client, job) == 5_000
    end

    test "cancels the visit and reports the fee charged", %{scope: scope, client: client} do
      job =
        job_fixture(scope, client, %{
          scheduled_date: Date.add(Date.utc_today(), 1),
          start_time: ~T[10:00:00],
          end_time: ~T[12:00:00]
        })

      assert {:ok, updated, 2_500} = Portal.cancel_visit(client, job)
      assert updated.status == :cancelled
    end

    test "refuses to cancel an already-cancelled visit", %{scope: scope, client: client} do
      job = job_fixture(scope, client, %{})
      {:ok, _updated, _fee} = Portal.cancel_visit(client, job)

      assert {:error, :not_modifiable} = Portal.cancel_visit(client, %{job | status: :cancelled})
    end
  end

  describe "get_cancellation_policy/1" do
    test "defaults to a 24-hour window with no fees when unset", %{account: account} do
      policy = Portal.get_cancellation_policy(account.id)

      assert policy.notice_window_hours == 24
      assert policy.late_fee_cents == 0
      assert policy.same_day_fee_cents == 0
    end
  end

  describe "invoices and payment" do
    setup %{scope: scope, client: client} do
      job = job_fixture(scope, client, %{status: :completed, agreed_price_cents: 15_000})
      {:ok, invoice} = Billing.create_invoice(scope, %{job_id: job.id, amount_cents: 15_000})
      %{job: job, invoice: invoice}
    end

    test "lists only this client's invoices", %{scope: scope, client: client, invoice: invoice} do
      {:ok, other_client} = Clients.create_client(scope, %{name: "Someone Else"})
      other_job = job_fixture(scope, other_client, %{status: :completed})

      {:ok, _other_invoice} =
        Billing.create_invoice(scope, %{job_id: other_job.id, amount_cents: 1})

      invoices = Portal.list_invoices(client)

      assert Enum.map(invoices, & &1.id) == [invoice.id]
    end

    test "pays an invoice, saves the card, and records a tip for the assigned cleaner", %{
      scope: scope,
      account: account,
      client: client,
      job: job,
      invoice: invoice
    } do
      cleaner = CleanerCrm.SchedulingFixtures.cleaner_fixture(scope, account)
      {:ok, job} = Scheduling.assign_cleaner(scope, job, cleaner.id)
      invoice = %{invoice | job: job}

      assert {:ok, updated_invoice} =
               Portal.pay_invoice(client, invoice, %{
                 "card_token" => "pm_card_visa",
                 "save_card" => "true",
                 "tip_cents" => "1000"
               })

      assert updated_invoice.status == :charge_pending

      reloaded_client = Portal.get_client!(client.id)
      assert reloaded_client.card_on_file

      period = CleanerCrm.TimeTracking.current_pay_period(scope)
      assert Portal.tip_cents_for_cleaner(scope, cleaner.id, period) == 1_000
    end

    test "paying without a tip adds nothing to the cleaner's earnings", %{
      scope: scope,
      account: account,
      client: client,
      job: job,
      invoice: invoice
    } do
      cleaner = CleanerCrm.SchedulingFixtures.cleaner_fixture(scope, account)
      {:ok, job} = Scheduling.assign_cleaner(scope, job, cleaner.id)
      invoice = %{invoice | job: job}

      assert {:ok, _updated_invoice} =
               Portal.pay_invoice(client, invoice, %{"card_token" => "pm_card_visa"})

      period = CleanerCrm.TimeTracking.current_pay_period(scope)
      assert Portal.tip_cents_for_cleaner(scope, cleaner.id, period) == 0
    end
  end
end
