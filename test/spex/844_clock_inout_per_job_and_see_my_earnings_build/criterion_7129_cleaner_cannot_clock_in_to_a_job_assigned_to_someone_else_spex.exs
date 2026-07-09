defmodule CleanerCrmSpex.Story844.Criterion7129Spex do
  @moduledoc """
  Story 844 — Clock in/out per job and see my earnings build
  Criterion 7129 — Cleaner cannot clock in to a job assigned to someone else

  Reconciled with story 838 criterion 7123: opening a job assigned to
  someone else redirects away entirely (the job page exposes entry codes,
  so unassigned cleaners must not see it at all). "Cannot clock in"
  follows from "cannot open".
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner cannot start time on a job assigned to someone else" do
    scenario "cleaner cannot clock in to a job assigned to someone else" do
      given_ "the owner has an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{scope: scope, account: account})}
      end

      given_ "a job at the Jones home is assigned to another cleaner, not me", context do
        other_cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "other-cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        me =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "me-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope, %{name: "Jones"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: other_cleaner.id,
            status: :scheduled
          })

        conn = Fixtures.log_in_user(context.conn, me)

        {:ok, Map.merge(context, %{me: me, job: job, conn: conn})}
      end

      when_ "I attempt to open that job", context do
        {:error, {:redirect, %{to: path, flash: flash}}} =
          live(context.conn, ~p"/field/jobs/#{context.job.id}")

        {:ok, Map.merge(context, %{redirect_path: path, redirect_flash: flash})}
      end

      then_ "I am redirected away and cannot see the job at all", context do
        assert context.redirect_path == ~p"/field"
        assert context.redirect_flash["error"] =~ "not assigned"

        {:ok, context}
      end

      then_ "I cannot start time on it", context do
        refute Map.has_key?(context, :job_live)

        {:ok, context}
      end
    end
  end
end
