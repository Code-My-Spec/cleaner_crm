defmodule CleanerCrmSpex.Story838.Criterion7121Spex do
  @moduledoc """
  Story 838 — Track time and per-job pay in one system
  Criterion 7121 — Cleaner clocks in and out of an assigned job
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner clocks in and out of their own assigned job" do
    scenario "cleaner clocks in and out of an assigned job" do
      given_ "the owner has an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{scope: scope, account: account})}
      end

      given_ "a cleaner is assigned to a job", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "priya-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            status: :scheduled
          })

        {:ok, Map.merge(context, %{cleaner: cleaner, job: job})}
      end

      given_ "the cleaner is logged in", context do
        conn = Fixtures.log_in_user(context.conn, context.cleaner)

        {:ok, Map.put(context, :conn, conn)}
      end

      when_ "the cleaner clocks in on the job", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        job_live
        |> element("[data-test='clock-in-button']")
        |> render_click()

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "the job shows as clocked in", context do
        assert render(context.job_live) =~ "Clocked in"
        assert has_element?(context.job_live, "[data-test='clock-out-button']")

        {:ok, context}
      end

      when_ "the cleaner clocks out of the job", context do
        context.job_live
        |> element("[data-test='clock-out-button']")
        |> render_click()

        {:ok, context}
      end

      then_ "the job shows as clocked out with the worked time recorded", context do
        html = render(context.job_live)

        assert html =~ "Clocked out"
        assert has_element?(context.job_live, "[data-test='worked-time']")

        {:ok, context}
      end
    end
  end
end
