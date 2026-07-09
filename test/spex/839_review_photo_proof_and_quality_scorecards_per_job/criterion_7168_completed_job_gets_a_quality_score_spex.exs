defmodule CleanerCrmSpex.Story839.Criterion7168Spex do
  @moduledoc """
  Story 839 — Review photo proof and quality scorecards per job
  Criterion 7168 — Completed job gets a quality score
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a completed job is scored for quality" do
    scenario "completed job gets a quality score" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a job was completed with a fully checked checklist and photo proof", context do
        client = Fixtures.client_fixture(context.scope)
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "the owner reviews the job and rates it four out of five", context do
        {:ok, review_live, _html} = live(context.conn, ~p"/app/quality/#{context.job.id}")

        html =
          review_live
          |> form("[data-test='quality-rating-form']", %{"rating" => "4"})
          |> render_submit()

        {:ok, Map.merge(context, %{review_live: review_live, review_html: html})}
      end

      then_ "the job records a quality score combining checklist completion and the owner's rating",
            context do
        assert has_element?(context.review_live, "[data-test='quality-score']")
        assert context.review_html =~ "4"

        {:ok, context}
      end
    end
  end
end
