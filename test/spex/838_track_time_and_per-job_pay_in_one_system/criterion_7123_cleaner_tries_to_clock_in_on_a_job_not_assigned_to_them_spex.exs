defmodule CleanerCrmSpex.Story838.Criterion7123Spex do
  @moduledoc """
  Story 838 — Track time and per-job pay in one system
  Criterion 7123 — Cleaner tries to clock in on a job not assigned to them
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner cannot clock in on another cleaner's job" do
    scenario "cleaner tries to clock in on a job not assigned to them" do
      given_ "the owner has an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{scope: scope, account: account})}
      end

      given_ "a job is assigned to cleaner Ana, and cleaner Ben also exists", context do
        ana =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "ana-#{System.unique_integer([:positive])}@example.com"
          })

        ben =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "ben-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: ana.id,
            status: :scheduled
          })

        {:ok, Map.merge(context, %{ana: ana, ben: ben, job: job})}
      end

      given_ "cleaner Ben is logged in", context do
        conn = Fixtures.log_in_user(context.conn, context.ben)

        {:ok, Map.put(context, :conn, conn)}
      end

      when_ "Ben attempts to open Ana's job to clock in", context do
        {:error, {:redirect, %{to: path, flash: flash}}} =
          live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        {:ok, Map.merge(context, %{redirect_path: path, redirect_flash: flash})}
      end

      then_ "Ben is redirected away with an error explaining the job isn't his", context do
        assert context.redirect_path == ~p"/app/field"
        assert context.redirect_flash["error"] =~ "not assigned"

        {:ok, context}
      end

      then_ "the job still shows no time recorded for its assigned cleaner Ana", context do
        ana_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), context.ana)

        {:ok, ana_job_live, _html} = live(ana_conn, ~p"/app/field/jobs/#{context.job.id}")

        assert has_element?(ana_job_live, "[data-test='clock-in-button']")
        refute has_element?(ana_job_live, "[data-test='clock-out-button']")

        {:ok, context}
      end
    end
  end
end
