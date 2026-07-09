defmodule CleanerCrmSpex.Story853.Criterion7246Spex do
  @moduledoc """
  Story 853 — Leave a review when the job is done well
  Criterion 7246 — No duplicate review request

  The request send itself is covered by criterion 7245's spec; this
  spec's subject is the scan's idempotency once a request has already
  gone out, so the already-sent request is seeded directly via
  `CleanerCrmSpex.Fixtures.review_request_fixture/4`.
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "the review-request scan never sends a second request for the same visit" do
    scenario "no duplicate review request" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "a completed visit already had its review request sent", context do
        client = Fixtures.client_fixture(context.scope)
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)
        Fixtures.review_request_fixture(context.scope, job, client)

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "the review-request scan runs again a day later", context do
        as_of = DateTime.add(DateTime.utc_now(), 48 * 60 * 60, :second)
        Fixtures.run_due_review_requests(as_of)

        {:ok, context}
      end

      then_ "no second review request is sent", context do
        refute_email_sent()

        {:ok, context}
      end
    end
  end
end
