defmodule CleanerCrmSpex.Story844.Criterion7126Spex do
  @moduledoc """
  Story 844 — Clock in/out per job and see my earnings build
  Criterion 7126 — Cleaner clocks in to their assigned job
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner clocks in to their own assigned job" do
    scenario "cleaner clocks in to their assigned job" do
      given_ "the owner has an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{scope: scope, account: account})}
      end

      given_ "I am a cleaner assigned to today's 9:00 AM job at the Smith home", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope, %{name: "Smith"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            status: :scheduled
          })

        conn = Fixtures.log_in_user(context.conn, cleaner)

        {:ok, Map.merge(context, %{cleaner: cleaner, job: job, conn: conn})}
      end

      when_ "I open that job and tap Clock In", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/field/jobs/#{context.job.id}")

        job_live
        |> element("[data-test='clock-in-button']")
        |> render_click()

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "I am clocked in", context do
        assert render(context.job_live) =~ "Clocked in"

        {:ok, context}
      end

      then_ "the job shows a running elapsed time starting now", context do
        assert has_element?(context.job_live, "[data-test='elapsed-time']")

        {:ok, context}
      end
    end
  end
end
