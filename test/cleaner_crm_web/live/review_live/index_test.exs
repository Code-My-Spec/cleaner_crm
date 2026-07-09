defmodule CleanerCrmWeb.ReviewLive.IndexTest do
  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Reviews
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Users.Scope

  defp owner_scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

    %{user: user, scope: %{scope | active_account: account, active_account_id: account.id}}
  end

  test "lists a submitted review and marks a private complaint", %{conn: conn} do
    %{user: owner, scope: scope} = owner_scope_fixture()

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

    {:ok, review} = Reviews.submit_review(review, 2, "The bathroom was not cleaned properly.")

    conn = log_in_user(conn, owner)
    {:ok, view, _html} = live(conn, ~p"/app/reviews")

    assert has_element?(
             view,
             "[data-test='review-row-#{review.id}']",
             "The bathroom was not cleaned properly."
           )

    assert has_element?(view, "[data-test='review-#{review.id}-visibility']", "Private")
  end
end
