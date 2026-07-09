defmodule CleanerCrmWeb.ReviewLive.PublicTest do
  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Reviews
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Users.Scope

  defp scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

    %{scope | active_account: account, active_account_id: account.id}
  end

  defp review_fixture(scope) do
    client =
      client_fixture(scope, %{
        name: "Jamie",
        email: "jamie-#{System.unique_integer([:positive])}@example.com"
      })

    {:ok, job} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        status: :completed,
        scheduled_date: Date.add(Date.utc_today(), -1),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00]
      })

    {:ok, review} =
      Reviews.create_review(scope, %{
        job_id: job.id,
        client_id: client.id,
        token: "tok-#{System.unique_integer([:positive])}",
        status: :review_requested,
        review_request_sent_at: DateTime.utc_now()
      })

    review
  end

  test "an invalid token shows an invalid-link notice", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/reviews/does-not-exist")
    assert has_element?(view, "[data-test='review-invalid-notice']")
  end

  test "a high rating publishes the review", %{conn: conn} do
    review = review_fixture(scope_fixture())

    {:ok, view, _html} = live(conn, ~p"/reviews/#{review.token}")

    view |> element("[data-test='review-rating-5']") |> render_click()
    view |> form("[data-test='review-form']", review: %{text: "Great!"}) |> render_submit()

    assert has_element?(view, "[data-test='review-published-notice']")
  end

  test "a low rating routes to a private complaint, not publication", %{conn: conn} do
    review = review_fixture(scope_fixture())

    {:ok, view, _html} = live(conn, ~p"/reviews/#{review.token}")

    view |> element("[data-test='review-rating-2']") |> render_click()
    view |> form("[data-test='review-form']", review: %{text: "Not great."}) |> render_submit()

    assert has_element?(view, "[data-test='review-private-notice']")
    refute has_element?(view, "[data-test='review-published-notice']")
  end
end
