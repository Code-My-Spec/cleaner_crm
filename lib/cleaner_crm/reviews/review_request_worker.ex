defmodule CleanerCrm.Reviews.ReviewRequestWorker do
  @moduledoc """
  On a job that's just been marked complete: sends the client an
  immediate thank-you note. Roughly 24 hours later — via the same
  Oban-cron scan pattern as
  `CleanerCrm.Notifications.ReminderScheduler` — it also sends the
  actual review request, skipping any job that already has a review
  (or private complaint) on file so a visit is never asked for a
  second time.

  `perform/1` handles both triggers: an immediate one-off insert with
  `job_id` args (from `CleanerCrm.Reviews.request_review/1`, called
  right after job completion) sends the thank-you, while the cron
  plugin's empty-args invocation runs the periodic scan.
  """

  use Oban.Worker, queue: :notifications

  import Ecto.Query
  require Logger

  alias CleanerCrm.Repo
  alias CleanerCrm.Clients.Client
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrm.Reviews.{Review, ReviewNotifier}

  @request_delay_seconds 24 * 60 * 60

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"job_id" => job_id}}) do
    Job
    |> Repo.get(job_id)
    |> Repo.preload(:client)
    |> send_thank_you()

    :ok
  end

  def perform(%Oban.Job{args: %{}}) do
    scan_and_send()
    :ok
  end

  @doc "Enqueues the immediate thank-you note for a job that was just marked complete."
  def enqueue_thank_you(job_id) do
    %{job_id: job_id} |> new() |> Oban.insert()
  end

  @doc "Sends every review request that's due right now, across every account."
  def scan_and_send(now \\ DateTime.utc_now()) do
    now
    |> due_jobs()
    |> Enum.each(&send_request_isolated(&1, now))
  end

  defp send_thank_you(%Job{client: %Client{email: email}} = job) when is_binary(email) do
    ReviewNotifier.deliver_thank_you(job.client, job)
  end

  defp send_thank_you(_job), do: :ok

  # One job's send failing must never stop the rest of the scan — each
  # job gets its own failure boundary rather than the whole `Enum.each`
  # aborting on the first raise.
  defp send_request_isolated(job, now) do
    send_review_request(job, now)
  rescue
    error ->
      Logger.error(
        "ReviewRequestWorker failed to send review request for job #{job.id}: " <>
          Exception.format(:error, error, __STACKTRACE__)
      )
  end

  defp due_jobs(now) do
    already_reviewed = from r in Review, where: r.job_id == parent_as(:job).id
    cutoff = DateTime.add(now, -@request_delay_seconds, :second)

    from(j in Job,
      as: :job,
      where: j.status == :completed,
      where: not is_nil(j.client_id),
      where: j.updated_at <= ^cutoff,
      where: not exists(already_reviewed),
      preload: [:client]
    )
    |> Repo.all()
  end

  defp send_review_request(%Job{} = job, now) do
    token = generate_token()

    %Review{account_id: job.account_id}
    |> Review.changeset(%{
      job_id: job.id,
      client_id: job.client_id,
      cleaner_id: job.cleaner_id,
      status: :review_requested,
      token: token,
      review_request_sent_at: now
    })
    |> Repo.insert!()

    {:ok, _email} = ReviewNotifier.deliver_review_request(job.client, job, review_url(token))

    :ok
  end

  defp generate_token, do: Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)

  # `CleanerCrmWeb.Endpoint.url()` is the standard phx.gen.auth-style
  # exception for building absolute links in outbound messages — see
  # the `dirty_xrefs` note on the `CleanerCrm` boundary.
  defp review_url(token), do: CleanerCrmWeb.Endpoint.url() <> "/reviews/#{token}"
end
