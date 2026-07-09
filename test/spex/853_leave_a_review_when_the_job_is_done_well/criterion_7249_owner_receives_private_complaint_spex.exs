defmodule CleanerCrmSpex.Story853.Criterion7249Spex do
  @moduledoc """
  Story 853 — Leave a review when the job is done well
  Criterion 7249 — Owner receives private complaint

  The routing decision itself is covered by criterion 7248's spec;
  this spec's subject is the office's own visibility into that
  complaint, via `ReviewLive.Index` at `/reviews` (route contract:
  "office, owner-only"). Assumes each row is
  `[data-test='review-row-<id>']` and a private review's row carries
  `[data-test='review-<id>-visibility']` reading "Private".
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a private complaint reaches the owner's review inbox" do
    scenario "owner receives private complaint" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client left a low rating with a private complaint", context do
        client = Fixtures.client_fixture(context.scope)
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)
        review = Fixtures.review_request_fixture(context.scope, job, client)

        {:ok, review_live, _html} =
          live(Phoenix.ConnTest.build_conn(), ~p"/reviews/#{review.token}")

        review_live
        |> element("[data-test='review-rating-2']")
        |> render_click()

        review_live
        |> form("[data-test='review-form']",
          review: %{text: "The bathroom was not cleaned properly."}
        )
        |> render_submit()

        {:ok, Map.merge(context, %{client: client, job: job, review: review})}
      end

      when_ "I open my review inbox", context do
        {:ok, reviews_live, _html} = live(context.conn, ~p"/reviews")

        {:ok, Map.put(context, :reviews_live, reviews_live)}
      end

      then_ "I see the client's complaint marked private", context do
        assert has_element?(
                 context.reviews_live,
                 "[data-test='review-row-#{context.review.id}']",
                 "The bathroom was not cleaned properly."
               )

        assert has_element?(
                 context.reviews_live,
                 "[data-test='review-#{context.review.id}-visibility']",
                 "Private"
               )

        {:ok, context}
      end
    end
  end
end
