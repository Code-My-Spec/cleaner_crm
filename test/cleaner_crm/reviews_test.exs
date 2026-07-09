defmodule CleanerCrm.ReviewsTest do
  use CleanerCrmTest.DataCase, async: false

  import Swoosh.TestAssertions

  alias CleanerCrm.{Accounts, ClientsFixtures, Reviews, Scheduling, UsersFixtures}
  alias CleanerCrm.Reviews.Review
  alias CleanerCrm.Users.Scope

  setup do
    user = UsersFixtures.user_fixture()
    scope = Scope.for_user(user)
    {:ok, account} = Accounts.create_account(scope, %{name: "Sparkle Co"})
    scope = %{scope | active_account_id: account.id, active_account: account}

    client =
      ClientsFixtures.client_fixture(scope, %{
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

    %{scope: scope, client: client, job: job}
  end

  test "create_review/2 scopes the review to the caller's active account", %{
    scope: scope,
    job: job,
    client: client
  } do
    assert {:ok, review} =
             Reviews.create_review(scope, %{
               job_id: job.id,
               client_id: client.id,
               token: "tok-#{System.unique_integer([:positive])}",
               status: :review_requested,
               review_request_sent_at: DateTime.utc_now()
             })

    assert review.account_id == scope.active_account_id
  end

  test "get_review_by_token/1 finds a review with no scope needed", %{
    scope: scope,
    job: job,
    client: client
  } do
    {:ok, review} =
      Reviews.create_review(scope, %{
        job_id: job.id,
        client_id: client.id,
        token: "findme-#{System.unique_integer([:positive])}",
        status: :review_requested,
        review_request_sent_at: DateTime.utc_now()
      })

    assert %Review{id: id} = Reviews.get_review_by_token(review.token)
    assert id == review.id
  end

  test "get_review_by_token/1 returns nil for an unknown token" do
    assert Reviews.get_review_by_token("nonexistent") == nil
  end

  test "list_reviews/1 lists only the account's own reviews, newest first", %{
    scope: scope,
    job: job,
    client: client
  } do
    {:ok, older} =
      Reviews.create_review(scope, %{
        job_id: job.id,
        client_id: client.id,
        token: "older-#{System.unique_integer([:positive])}",
        status: :review_requested,
        review_request_sent_at: DateTime.utc_now()
      })

    {:ok, other_account} = Accounts.create_account(scope, %{name: "Other Co"})
    other_scope = %{scope | active_account_id: other_account.id, active_account: other_account}
    other_client = ClientsFixtures.client_fixture(other_scope, %{name: "Other Client"})

    {:ok, other_job} =
      Scheduling.create_job(other_scope, %{
        client_id: other_client.id,
        status: :completed,
        scheduled_date: Date.add(Date.utc_today(), -1),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00]
      })

    {:ok, _other_review} =
      Reviews.create_review(other_scope, %{
        job_id: other_job.id,
        client_id: other_client.id,
        token: "other-#{System.unique_integer([:positive])}",
        status: :review_requested,
        review_request_sent_at: DateTime.utc_now()
      })

    assert [%Review{id: id}] = Reviews.list_reviews(scope)
    assert id == older.id
  end

  test "submit_review/3 publishes a high rating", %{scope: scope, job: job, client: client} do
    {:ok, review} =
      Reviews.create_review(scope, %{
        job_id: job.id,
        client_id: client.id,
        token: "pub-#{System.unique_integer([:positive])}",
        status: :review_requested,
        review_request_sent_at: DateTime.utc_now()
      })

    assert {:ok, updated} = Reviews.submit_review(review, 5, "Wonderful!")
    assert updated.status == :published
    assert updated.rating == 5
    assert updated.text == "Wonderful!"
    assert updated.submitted_at
  end

  test "submit_review/3 routes a low rating to a private complaint", %{
    scope: scope,
    job: job,
    client: client
  } do
    {:ok, review} =
      Reviews.create_review(scope, %{
        job_id: job.id,
        client_id: client.id,
        token: "priv-#{System.unique_integer([:positive])}",
        status: :review_requested,
        review_request_sent_at: DateTime.utc_now()
      })

    assert {:ok, updated} = Reviews.submit_review(review, 2, "Not great.")
    assert updated.status == :private
  end

  test "request_review/1 sends the immediate thank-you", %{job: job, client: client} do
    Reviews.request_review(job)

    assert_email_sent(to: client.email, subject: ~r/thank/i)
  end

  test "send_due_review_requests/1 runs the periodic scan", %{
    scope: scope,
    job: job,
    client: client
  } do
    as_of = DateTime.add(DateTime.utc_now(), 24 * 60 * 60, :second)
    Reviews.send_due_review_requests(as_of)

    assert_email_sent(to: client.email, subject: ~r/review/i)
    assert %Review{} = Reviews.get_review_by_token(review_token_for(scope, job))
  end

  defp review_token_for(scope, job) do
    scope
    |> Reviews.list_reviews()
    |> Enum.find(&(&1.job_id == job.id))
    |> Map.fetch!(:token)
  end
end
