defmodule CleanerCrm.TimeTrackingTest do
  use CleanerCrmTest.DataCase

  alias CleanerCrm.Accounts
  alias CleanerCrm.Clients
  alias CleanerCrm.Scheduling
  alias CleanerCrm.TimeTracking
  alias CleanerCrm.Users.Scope

  import CleanerCrm.UsersFixtures

  setup do
    owner = user_fixture()
    owner_scope = Scope.for_user(owner)
    {:ok, account} = Accounts.create_account(owner_scope, %{name: "Sparkle Co"})

    cleaner = user_fixture()
    {:ok, _member} = Accounts.add_user_to_account(owner_scope, cleaner.id, account.id, :member)

    scope = %{owner_scope | active_account_id: account.id, active_account: account}

    {:ok, client} = Clients.create_client(scope, %{name: "A Client"})

    %{scope: scope, cleaner: cleaner, client: client}
  end

  defp job_fixture(scope, client, cleaner, attrs) do
    {:ok, job} =
      Scheduling.create_job(
        scope,
        Enum.into(attrs, %{
          client_id: client.id,
          cleaner_id: cleaner.id,
          scheduled_date: Date.utc_today(),
          start_time: ~T[09:00:00],
          end_time: ~T[11:00:00],
          status: :scheduled
        })
      )

    job
  end

  describe "clock_in/2 and clock_out/2" do
    test "rejects a cleaner who isn't assigned to the job", %{
      scope: scope,
      client: client,
      cleaner: assigned_cleaner
    } do
      job = job_fixture(scope, client, assigned_cleaner, %{})
      someone_else_scope = %{scope | user: user_fixture()}

      assert {:error, :not_assigned} = TimeTracking.clock_in(someone_else_scope, job)
    end

    test "clocks in and out, recording worked time", %{
      scope: scope,
      client: client,
      cleaner: cleaner
    } do
      job = job_fixture(scope, client, cleaner, %{})
      cleaner_scope = %{scope | user: cleaner}

      assert {:ok, entry} = TimeTracking.clock_in(cleaner_scope, job)
      assert entry.clocked_out_at == nil

      assert {:ok, resolved} = TimeTracking.clock_out(cleaner_scope, job)
      assert resolved.clocked_out_at != nil
    end

    test "refuses a second clock-in while already clocked in elsewhere", %{
      scope: scope,
      client: client,
      cleaner: cleaner
    } do
      job_a = job_fixture(scope, client, cleaner, %{})
      job_b = job_fixture(scope, client, cleaner, %{})
      cleaner_scope = %{scope | user: cleaner}

      assert {:ok, _entry} = TimeTracking.clock_in(cleaner_scope, job_a)
      assert {:error, {:already_clocked_in, ^job_a}} = TimeTracking.clock_in(cleaner_scope, job_b)
    end
  end

  describe "pay calculations via list_job_time_summaries/2" do
    test "an hourly job's pay accumulates into the cleaner's period total", %{
      scope: scope,
      client: client,
      cleaner: cleaner
    } do
      hourly_job =
        job_fixture(scope, client, cleaner, %{
          pay_type: :hourly,
          hourly_rate_cents: 2500,
          status: :completed
        })

      TimeTracking.create_time_entry(scope, %{
        job_id: hourly_job.id,
        clocked_in_at: ~U[2024-01-08 09:00:00Z],
        clocked_out_at: ~U[2024-01-08 11:30:00Z]
      })

      period = TimeTracking.pay_period_for(~D[2024-01-08])
      totals = TimeTracking.cleaner_pay_totals(scope, period)

      assert totals[cleaner.id] == 6250
    end

    test "an unresolved entry is excluded from the pay total and blocks export", %{
      scope: scope,
      client: client,
      cleaner: cleaner
    } do
      job =
        job_fixture(scope, client, cleaner, %{
          status: :scheduled,
          pay_type: :hourly,
          hourly_rate_cents: 2000
        })

      {:ok, entry} =
        TimeTracking.create_time_entry(scope, %{
          job_id: job.id,
          clocked_in_at: ~U[2024-01-08 09:00:00Z]
        })

      period = TimeTracking.pay_period_for(~D[2024-01-08])

      assert TimeTracking.cleaner_pay_totals(scope, period)[cleaner.id] == 0
      assert {:error, :unresolved_entries} = TimeTracking.export_pay_period_csv(scope, period)

      {:ok, _resolved} =
        TimeTracking.resolve_clock_out(scope, entry, %{clock_out_time: "11:00"})

      assert {:ok, csv} = TimeTracking.export_pay_period_csv(scope, period)
      assert csv =~ cleaner.email
    end

    test "a piece-rate job with an open entry still blocks export, despite having a price", %{
      scope: scope,
      client: client,
      cleaner: cleaner
    } do
      job =
        job_fixture(scope, client, cleaner, %{
          status: :scheduled,
          pay_type: :piece_rate,
          piece_rate_cents: 8000
        })

      TimeTracking.create_time_entry(scope, %{
        job_id: job.id,
        clocked_in_at: ~U[2024-01-08 09:00:00Z]
      })

      period = TimeTracking.pay_period_for(~D[2024-01-08])

      assert [%{unresolved?: true}] = TimeTracking.list_job_time_summaries(scope, period)
      assert {:error, :unresolved_entries} = TimeTracking.export_pay_period_csv(scope, period)
    end
  end
end
