defmodule CleanerCrmSpex.Story844.Criterion7138Spex do
  @moduledoc """
  Story 844 — Clock in/out per job and see my earnings build
  Criterion 7138 — Hourly job earnings computed from clocked time

  Getting clocked in is covered end-to-end by this story's own
  "cleaner clocks in to their assigned job" spec (criterion 7126).
  This spec's subject is the earnings-on-clock-out calculation, so the
  2 hours of already-elapsed clocked time is seeded directly via
  `CleanerCrmSpex.Fixtures` as an open (not yet clocked-out) time
  entry — the clock-out itself is driven live, which is the action
  under test.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "an hourly job's earnings are computed from the clocked time when the cleaner clocks out" do
    scenario "hourly job earnings computed from clocked time" do
      given_ "the owner has an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{scope: scope, account: account})}
      end

      given_ "the Smith job pays hourly at $25/hour", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope, %{name: "Smith"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            pay_type: :hourly,
            hourly_rate_cents: 2500,
            status: :scheduled
          })

        conn = Fixtures.log_in_user(context.conn, cleaner)

        {:ok, Map.merge(context, %{job: job, conn: conn})}
      end

      given_ "I have 2 hours of clocked time on that job already", context do
        Fixtures.time_entry_fixture(context.scope, context.job, %{
          clocked_in_at: DateTime.add(DateTime.utc_now(), -2, :hour),
          clocked_out_at: nil
        })

        {:ok, context}
      end

      when_ "I clock out", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        job_live
        |> element("[data-test='clock-out-button']")
        |> render_click()

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "the job shows earnings of $50 for that visit", context do
        assert render(context.job_live) =~ "$50.00"

        {:ok, context}
      end
    end
  end
end
