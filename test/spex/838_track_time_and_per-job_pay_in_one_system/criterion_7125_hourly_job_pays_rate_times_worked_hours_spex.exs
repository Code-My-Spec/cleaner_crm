defmodule CleanerCrmSpex.Story838.Criterion7125Spex do
  @moduledoc """
  Story 838 — Track time and per-job pay in one system
  Criterion 7125 — Hourly job pays rate times worked hours

  Clocking in and out through the UI is covered end-to-end by story
  838's own "cleaner clocks in and out of an assigned job" spec
  (drives FieldLive.Job). This spec's subject is the hourly-pay
  calculation, so a resolved time entry with explicit clock-in/out
  timestamps is seeded directly via `CleanerCrmSpex.Fixtures` rather
  than re-driving the clock-in/out flow here.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "an hourly job pays the cleaner's rate times the hours worked" do
    scenario "hourly job pays rate times worked hours" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, scope: scope, account: account})}
      end

      given_ "a cleaner has an hourly job paying $25.00/hr", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "hourly-cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            pay_type: :hourly,
            hourly_rate_cents: 2500,
            status: :completed
          })

        {:ok, Map.merge(context, %{cleaner: cleaner, job: job})}
      end

      given_ "the cleaner has a resolved time entry of 2 hours 30 minutes on that job", context do
        Fixtures.time_entry_fixture(context.scope, context.job, %{
          clocked_in_at: ~U[2024-01-08 09:00:00Z],
          clocked_out_at: ~U[2024-01-08 11:30:00Z]
        })

        {:ok, context}
      end

      when_ "the owner opens the timesheet", context do
        {:ok, timesheet_live, html} = live(context.conn, ~p"/app/timesheets")

        {:ok, Map.merge(context, %{timesheet_live: timesheet_live, timesheet_html: html})}
      end

      then_ "the job's pay is the hourly rate times the hours worked", context do
        assert context.timesheet_html =~ context.cleaner.email
        assert context.timesheet_html =~ "$62.50"

        {:ok, context}
      end
    end
  end
end
