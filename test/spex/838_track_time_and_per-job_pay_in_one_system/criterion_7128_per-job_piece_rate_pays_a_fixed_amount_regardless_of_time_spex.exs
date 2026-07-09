defmodule CleanerCrmSpex.Story838.Criterion7128Spex do
  @moduledoc """
  Story 838 — Track time and per-job pay in one system
  Criterion 7128 — Per-job piece rate pays a fixed amount regardless of time

  Clocking in and out through the UI is covered end-to-end by story
  838's own "cleaner clocks in and out of an assigned job" spec. This
  spec's subject is the piece-rate pay calculation, so a resolved time
  entry is seeded directly via `CleanerCrmSpex.Fixtures` rather than
  re-driving the clock-in/out flow here.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a piece-rate job pays a fixed amount no matter how long it takes" do
    scenario "per-job piece rate pays a fixed amount regardless of time" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, scope: scope, account: account})}
      end

      given_ "a cleaner has a piece-rate job worth a flat $80.00", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "piece-rate-cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            pay_type: :piece_rate,
            piece_rate_cents: 8000,
            status: :completed
          })

        {:ok, Map.merge(context, %{cleaner: cleaner, job: job})}
      end

      given_ "the cleaner completed the job in 2 hours on one visit", context do
        Fixtures.time_entry_fixture(context.scope, context.job, %{
          clocked_in_at: ~U[2024-01-09 09:00:00Z],
          clocked_out_at: ~U[2024-01-09 11:00:00Z]
        })

        {:ok, context}
      end

      when_ "the owner opens the timesheet", context do
        {:ok, timesheet_live, html} = live(context.conn, ~p"/timesheets")

        {:ok, Map.merge(context, %{timesheet_live: timesheet_live, timesheet_html: html})}
      end

      then_ "the job pays the flat piece rate regardless of hours worked", context do
        assert context.timesheet_html =~ "$80.00"
        refute context.timesheet_html =~ "$160.00"

        {:ok, context}
      end
    end
  end
end
