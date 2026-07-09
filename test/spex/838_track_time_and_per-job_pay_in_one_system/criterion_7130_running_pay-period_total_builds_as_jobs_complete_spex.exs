defmodule CleanerCrmSpex.Story838.Criterion7130Spex do
  @moduledoc """
  Story 838 — Track time and per-job pay in one system
  Criterion 7130 — Running pay-period total builds as jobs complete

  Clocking in and out through the UI is covered end-to-end by story
  838's own "cleaner clocks in and out of an assigned job" spec. This
  spec's subject is the running pay-period total across mixed pay
  models, so resolved time entries are seeded directly via
  `CleanerCrmSpex.Fixtures` rather than re-driving the clock-in/out
  flow for every job.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the pay-period total grows as each of the cleaner's jobs completes" do
    scenario "running pay-period total builds as jobs complete" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, scope: scope, account: account})}
      end

      given_ "the account has a cleaner", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "running-total-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope)

        {:ok, Map.merge(context, %{cleaner: cleaner, client: client})}
      end

      given_ "the pay period already has an hourly job recorded paying $62.50", context do
        hourly_job =
          Fixtures.job_fixture(context.scope, context.client, %{
            cleaner_id: context.cleaner.id,
            pay_type: :hourly,
            hourly_rate_cents: 2500,
            status: :completed
          })

        Fixtures.time_entry_fixture(context.scope, hourly_job, %{
          clocked_in_at: ~U[2024-01-08 09:00:00Z],
          clocked_out_at: ~U[2024-01-08 11:30:00Z]
        })

        {:ok, context}
      end

      when_ "the owner opens the timesheet for the current pay period", context do
        {:ok, timesheet_live, html} = live(context.conn, ~p"/timesheets")

        {:ok, Map.merge(context, %{timesheet_live: timesheet_live, timesheet_html: html})}
      end

      then_ "the running total reflects the recorded hourly job", context do
        assert context.timesheet_html =~ "$62.50"

        {:ok, context}
      end

      when_ "the cleaner completes a second piece-rate job paying $80.00", context do
        piece_rate_job =
          Fixtures.job_fixture(context.scope, context.client, %{
            cleaner_id: context.cleaner.id,
            pay_type: :piece_rate,
            piece_rate_cents: 8000,
            status: :completed
          })

        Fixtures.time_entry_fixture(context.scope, piece_rate_job, %{
          clocked_in_at: ~U[2024-01-09 09:00:00Z],
          clocked_out_at: ~U[2024-01-09 11:00:00Z]
        })

        {:ok, context}
      end

      then_ "the running total grows to include the new job", context do
        {:ok, _timesheet_live, html} = live(context.conn, ~p"/timesheets")

        assert html =~ "$142.50"

        {:ok, context}
      end
    end
  end
end
