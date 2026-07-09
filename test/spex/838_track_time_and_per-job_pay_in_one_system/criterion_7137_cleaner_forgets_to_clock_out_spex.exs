defmodule CleanerCrmSpex.Story838.Criterion7137Spex do
  @moduledoc """
  Story 838 — Track time and per-job pay in one system
  Criterion 7137 — Cleaner forgets to clock out
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner clocks in on a job but never clocks out" do
    scenario "cleaner forgets to clock out" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        owner_conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{owner_conn: owner_conn, scope: scope, account: account})}
      end

      given_ "a cleaner is assigned to an hourly job", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "forgetful-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            pay_type: :hourly,
            hourly_rate_cents: 2000,
            status: :scheduled
          })

        {:ok, Map.merge(context, %{cleaner: cleaner, job: job})}
      end

      given_ "the cleaner is logged in", context do
        conn = Fixtures.log_in_user(context.conn, context.cleaner)

        {:ok, Map.put(context, :conn, conn)}
      end

      when_ "the cleaner clocks in and then leaves without clocking out", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        job_live
        |> element("[data-test='clock-in-button']")
        |> render_click()

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "the owner sees the time entry flagged as missing a clock-out", context do
        {:ok, timesheet_live, html} = live(context.owner_conn, ~p"/app/timesheets")

        assert html =~ "Missing clock-out"

        assert has_element?(
                 timesheet_live,
                 "[data-test='unresolved-entry-job-#{context.job.id}']"
               )

        {:ok, context}
      end

      then_ "the cleaner is prompted to resolve the missing clock-out", context do
        {:ok, _job_live, html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        assert html =~ "Missing clock-out"

        {:ok, context}
      end

      then_ "the flagged entry is excluded from the cleaner's pay total", context do
        {:ok, timesheet_live, _html} = live(context.owner_conn, ~p"/app/timesheets")

        assert has_element?(
                 timesheet_live,
                 "[data-test='cleaner-pay-total-#{context.cleaner.id}']",
                 "$0.00"
               )

        {:ok, context}
      end

      when_ "the owner sets the missing clock-out time to resolve the entry", context do
        {:ok, timesheet_live, _html} = live(context.owner_conn, ~p"/app/timesheets")

        timesheet_live
        |> form("[data-test='resolve-clock-out-form-#{context.job.id}']",
          time_entry: %{clock_out_time: "17:00"}
        )
        |> render_submit()

        {:ok, Map.put(context, :timesheet_live, timesheet_live)}
      end

      then_ "the entry is resolved and the cleaner's pay total updates to include it", context do
        refute has_element?(
                 context.timesheet_live,
                 "[data-test='unresolved-entry-job-#{context.job.id}']"
               )

        refute render(context.timesheet_live) =~ "Missing clock-out"

        refute has_element?(
                 context.timesheet_live,
                 "[data-test='cleaner-pay-total-#{context.cleaner.id}']",
                 "$0.00"
               )

        {:ok, context}
      end
    end
  end
end
