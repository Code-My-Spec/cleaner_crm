defmodule CleanerCrmSpex.Story853.Criterion7250Spex do
  @moduledoc """
  Story 853 — Leave a review when the job is done well
  Criterion 7250 — No review prompt for incomplete visit

  A visit that was never completed must never trigger a review
  request, no matter how much time passes.
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "an incomplete visit never gets a review prompt" do
    scenario "no review prompt for incomplete visit" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "a client's visit is still in progress, not completed", context do
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            status: :in_progress,
            scheduled_date: Date.add(Date.utc_today(), -2)
          })

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "several days pass", context do
        as_of = DateTime.add(DateTime.utc_now(), 5 * 24 * 60 * 60, :second)
        Fixtures.run_due_review_requests(as_of)

        {:ok, context}
      end

      then_ "no review request is ever sent for that visit", context do
        refute_email_sent()

        {:ok, context}
      end
    end
  end
end
