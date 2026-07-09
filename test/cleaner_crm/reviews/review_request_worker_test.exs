defmodule CleanerCrm.Reviews.ReviewRequestWorkerTest do
  use CleanerCrmTest.DataCase, async: false

  import Swoosh.TestAssertions

  alias CleanerCrm.{Accounts, ClientsFixtures, Repo, Scheduling, UsersFixtures}
  alias CleanerCrm.Reviews.{Review, ReviewRequestWorker}
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

    %{scope: scope, client: client}
  end

  defp completed_job_fixture(scope, client, attrs \\ %{}) do
    {:ok, job} =
      attrs
      |> Enum.into(%{
        client_id: client.id,
        agreed_price: Decimal.new("150.00"),
        status: :completed,
        scheduled_date: Date.add(Date.utc_today(), -1),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00]
      })
      |> then(&Scheduling.create_job(scope, &1))

    job
  end

  test "enqueue_thank_you/1 sends the client an immediate thank-you", %{
    scope: scope,
    client: client
  } do
    job = completed_job_fixture(scope, client)

    ReviewRequestWorker.enqueue_thank_you(job.id)

    assert_email_sent(to: client.email, subject: ~r/thank/i)
  end

  test "scan_and_send/1 sends the review request once ~24h have passed and records it", %{
    scope: scope,
    client: client
  } do
    job = completed_job_fixture(scope, client)

    as_of = DateTime.add(DateTime.utc_now(), 24 * 60 * 60, :second)
    ReviewRequestWorker.scan_and_send(as_of)

    assert_email_sent(to: client.email, subject: ~r/review/i)
    assert %Review{status: :review_requested} = Repo.get_by!(Review, job_id: job.id)
  end

  test "scan_and_send/1 does not send before ~24h have passed", %{scope: scope, client: client} do
    completed_job_fixture(scope, client)

    ReviewRequestWorker.scan_and_send(DateTime.utc_now())

    refute_email_sent()
  end

  test "scan_and_send/1 skips a job that already has a review on file", %{
    scope: scope,
    client: client
  } do
    job = completed_job_fixture(scope, client)

    %Review{account_id: scope.active_account_id}
    |> Review.changeset(%{
      job_id: job.id,
      client_id: client.id,
      status: :review_requested,
      token: "already-sent-#{System.unique_integer([:positive])}",
      review_request_sent_at: DateTime.utc_now()
    })
    |> Repo.insert!()

    as_of = DateTime.add(DateTime.utc_now(), 48 * 60 * 60, :second)
    ReviewRequestWorker.scan_and_send(as_of)

    refute_email_sent()
  end

  test "scan_and_send/1 skips a job that was never completed", %{scope: scope, client: client} do
    {:ok, _job} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        status: :in_progress,
        scheduled_date: Date.add(Date.utc_today(), -2),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00]
      })

    as_of = DateTime.add(DateTime.utc_now(), 5 * 24 * 60 * 60, :second)
    ReviewRequestWorker.scan_and_send(as_of)

    refute_email_sent()
  end
end
