defmodule CleanerCrmSpex.Story844.Criterion7144Spex do
  @moduledoc """
  Story 844 — Clock in/out per job and see my earnings build
  Criterion 7144 — Running pay-period total grows as jobs complete

  A job's own earnings computation (hourly or piece-rate) is covered
  by this story's own criteria 7138 and 7141. This spec's subject is
  the pay-period running total on the cleaner's earnings summary, so
  two already-completed jobs with resolved time entries are seeded
  directly via `CleanerCrmSpex.Fixtures` rather than re-driving
  clock-in/clock-out for each one.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the cleaner's pay-period running total grows as jobs complete" do
    scenario "running pay-period total grows as jobs complete" do
      given_ "the owner has an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{scope: scope, account: account})}
      end

      given_ "I have completed two jobs this pay period earning $50 and $60", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope)

        hourly_job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            pay_type: :hourly,
            hourly_rate_cents: 2500,
            status: :completed
          })

        Fixtures.time_entry_fixture(context.scope, hourly_job, %{
          clocked_in_at: ~U[2024-01-08 09:00:00Z],
          clocked_out_at: ~U[2024-01-08 11:00:00Z]
        })

        piece_rate_job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            pay_type: :piece_rate,
            piece_rate_cents: 6000,
            status: :completed
          })

        Fixtures.time_entry_fixture(context.scope, piece_rate_job, %{
          clocked_in_at: ~U[2024-01-09 09:00:00Z],
          clocked_out_at: ~U[2024-01-09 11:00:00Z]
        })

        conn = Fixtures.log_in_user(context.conn, cleaner)

        {:ok, Map.put(context, :conn, conn)}
      end

      when_ "I view my earnings summary", context do
        {:ok, field_live, html} = live(context.conn, ~p"/app/field")

        {:ok, Map.merge(context, %{field_live: field_live, html: html})}
      end

      then_ "the current pay period shows a running total of $110", context do
        assert context.html =~ "$110.00"

        {:ok, context}
      end
    end
  end
end
