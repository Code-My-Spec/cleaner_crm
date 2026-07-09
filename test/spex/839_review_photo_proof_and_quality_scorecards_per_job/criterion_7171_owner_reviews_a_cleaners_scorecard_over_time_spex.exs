defmodule CleanerCrmSpex.Story839.Criterion7171Spex do
  @moduledoc """
  Story 839 — Review photo proof and quality scorecards per job
  Criterion 7171 — Owner reviews a cleaner's scorecard over time
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "an owner reviews how a cleaner's quality trends across completed jobs" do
    scenario "owner reviews a cleaner's scorecard over time" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "cleaner Ana has completed three jobs with photo proof over time", context do
        client = Fixtures.client_fixture(context.scope)

        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{email: "ana@example.com"})

        jobs =
          Enum.map(1..3, fn _n ->
            Fixtures.job_with_proof_of_work_fixture(context.scope, client, %{
              cleaner_id: cleaner.id
            })
          end)

        {:ok, Map.merge(context, %{client: client, cleaner: cleaner, jobs: jobs})}
      end

      when_ "the owner opens Ana's scorecard", context do
        {:ok, scorecards_live, _html} = live(context.conn, ~p"/quality/scorecards")

        html =
          scorecards_live
          |> element("[data-test='scorecard-cleaner-#{context.cleaner.id}']")
          |> render_click()

        {:ok, Map.merge(context, %{scorecards_live: scorecards_live, scorecards_html: html})}
      end

      then_ "the scorecard shows Ana's average score across her jobs", context do
        assert has_element?(context.scorecards_live, "[data-test='scorecard-average-score']")

        {:ok, context}
      end

      then_ "the scorecard shows the trend so the owner can coach on declining areas", context do
        assert has_element?(context.scorecards_live, "[data-test='scorecard-trend']")

        {:ok, context}
      end
    end
  end
end
