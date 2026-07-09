defmodule CleanerCrmSpex.Story853.Criterion7247Spex do
  @moduledoc """
  Story 853 — Leave a review when the job is done well
  Criterion 7247 — High rating routes to publish

  Route contract: `GET /reviews/:token` is `ReviewLive.Public` — 1-5
  stars plus text. Assumes the rating control is
  `[data-test='review-rating-<n>']` (n from 1 to 5), the text field is
  `review[text]`, the submit button is
  `[data-test='submit-review-button']`, and a rating of 4 or 5 shows
  `[data-test='review-published-notice']` on submit.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a high rating routes the review toward publishing" do
    scenario "high rating routes to publish" do
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

      when_ "I rate the visit 5 stars with a kind note", context do
        {:ok, review_live, _html} = live(context.conn, ~p"/reviews/#{context.review.token}")

        review_live
        |> element("[data-test='review-rating-5']")
        |> render_click()

        review_live
        |> form("[data-test='review-form']", review: %{text: "Wonderful, thorough cleaning!"})
        |> render_submit()

        {:ok, Map.put(context, :review_live, review_live)}
      end

      then_ "I see my review is on its way to being published", context do
        assert has_element?(context.review_live, "[data-test='review-published-notice']")

        {:ok, context}
      end
    end
  end
end
