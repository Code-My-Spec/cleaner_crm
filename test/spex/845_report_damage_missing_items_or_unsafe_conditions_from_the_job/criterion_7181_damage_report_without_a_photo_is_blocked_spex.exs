defmodule CleanerCrmSpex.Story845.Criterion7181Spex do
  @moduledoc """
  Story 845 — Report damage, missing items, or unsafe conditions from the job
  Criterion 7181 — Damage report without a photo is blocked
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a damage report cannot be filed without a photo" do
    scenario "damage report without a photo is blocked" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        owner_conn = Fixtures.log_in_user(context.conn, user)

        {:ok,
         Map.merge(context, %{owner_conn: owner_conn, user: user, scope: scope, account: account})}
      end

      given_ "cleaner Ana is logged in on her assigned, in-progress job", context do
        client = Fixtures.client_fixture(context.scope)

        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{email: "ana@example.com"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            status: :in_progress
          })

        conn = Fixtures.log_in_user(build_conn(), cleaner)

        {:ok, Map.merge(context, %{client: client, cleaner: cleaner, job: job, conn: conn})}
      end

      when_ "Ana tries to file a damage report with only a description, no photo", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/field/jobs/#{context.job.id}")

        html =
          job_live
          |> form("[data-test='incident-report-form']",
            incident: %{
              type: "damage",
              description: "Living room floor lamp is cracked and won't stand upright"
            }
          )
          |> render_submit()

        {:ok, Map.merge(context, %{job_live: job_live, html_after_attempt: html})}
      end

      then_ "the report is blocked and Ana is told a photo is required", context do
        assert context.html_after_attempt =~ "photo"
        refute has_element?(context.job_live, "[data-test='incident-report-item']")

        {:ok, context}
      end

      then_ "the owner never sees a phantom damage report for this job", context do
        {:ok, _review_live, html} = live(context.owner_conn, ~p"/quality")

        assert html =~ context.client.name
        refute html =~ "Living room floor lamp is cracked and won't stand upright"

        {:ok, context}
      end
    end
  end
end
