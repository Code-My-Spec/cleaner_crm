defmodule CleanerCrmSpex.Story853.Criterion7248Spex do
  @moduledoc """
  Story 853 — Leave a review when the job is done well
  Criterion 7248 — Low rating routes to private complaint

  Story description: "a rating <=3 offers private complaint path".
  Assumes the same rating control and form as criterion 7247's spec,
  with a rating of 3 or below showing
  `[data-test='review-private-notice']` instead of the published
  notice.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a low rating routes the review to a private complaint instead of publishing" do
    scenario "low rating routes to private complaint" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "I have a pending review request for a completed visit", context do
        client = Fixtures.client_fixture(context.scope)
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)
        review = Fixtures.review_request_fixture(context.scope, job, client)

        {:ok, Map.merge(context, %{client: client, job: job, review: review})}
      end

      when_ "I rate the visit 2 stars and explain what went wrong", context do
        {:ok, review_live, _html} = live(context.conn, ~p"/reviews/#{context.review.token}")

        review_live
        |> element("[data-test='review-rating-2']")
        |> render_click()

        review_live
        |> form("[data-test='review-form']",
          review: %{text: "The bathroom was not cleaned properly."}
        )
        |> render_submit()

        {:ok, Map.put(context, :review_live, review_live)}
      end

      then_ "I'm offered a private path instead of a public posting", context do
        assert has_element?(context.review_live, "[data-test='review-private-notice']")
        refute has_element?(context.review_live, "[data-test='review-published-notice']")

        {:ok, context}
      end
    end
  end
end
