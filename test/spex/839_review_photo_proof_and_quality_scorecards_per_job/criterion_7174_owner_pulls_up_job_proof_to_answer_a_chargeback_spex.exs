defmodule CleanerCrmSpex.Story839.Criterion7174Spex do
  @moduledoc """
  Story 839 — Review photo proof and quality scorecards per job
  Criterion 7174 — Owner pulls up job proof to answer a chargeback
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "an owner pulls up a job's proof-of-work to contest a chargeback" do
    scenario "owner pulls up job proof to answer a chargeback" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client disputing a charge had a completed job with photo proof", context do
        client = Fixtures.client_fixture(context.scope, %{name: "Riverside Bungalow"})
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "the owner opens the completed job to answer the chargeback", context do
        {:ok, review_live, html} = live(context.conn, ~p"/quality/#{context.job.id}")

        {:ok, Map.merge(context, %{review_live: review_live, review_html: html})}
      end

      then_ "the owner sees the completed checklist as proof the work was performed", context do
        assert context.review_html =~ "Kitchen counters wiped down"
        assert context.review_html =~ "Bathrooms sanitized"

        {:ok, context}
      end

      then_ "the owner sees timestamped before and after photos as proof", context do
        assert has_element?(context.review_live, "[data-test='proof-of-work-photo']")
        assert has_element?(context.review_live, "[data-test='proof-of-work-photo-timestamp']")

        {:ok, context}
      end
    end
  end
end
