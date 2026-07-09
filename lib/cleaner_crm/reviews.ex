defmodule CleanerCrm.Reviews do
  @moduledoc """
  Post-visit review collection: an immediate thank-you plus a delayed
  review request after job completion
  (`CleanerCrm.Reviews.ReviewRequestWorker`), token-based public
  submission with a 1-5 star rating and free text, and the office's
  inbox over what comes back. A rating of 3 or below routes the
  submission to a private complaint for the owner instead of
  publication.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Repo
  alias CleanerCrm.Reviews.{Review, ReviewRequestWorker}
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrm.Users.Scope

  @doc "Enqueues the immediate post-completion thank-you for a job — see `ReviewRequestWorker`."
  def request_review(%Job{} = job), do: ReviewRequestWorker.enqueue_thank_you(job.id)

  @doc "Runs the periodic review-request scan now — see `ReviewRequestWorker`."
  defdelegate send_due_review_requests(now \\ DateTime.utc_now()),
    to: ReviewRequestWorker,
    as: :scan_and_send

  @doc "Creates a review directly, scoped to the caller's active account."
  def create_review(%Scope{active_account_id: account_id}, attrs) when not is_nil(account_id) do
    %Review{account_id: account_id}
    |> Review.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Looks up a review by its public request token — no `Scope`, reached
  from an unauthenticated client's emailed link.
  """
  def get_review_by_token(token) when is_binary(token) do
    Review
    |> where([r], r.token == ^token)
    |> preload([:job, :client])
    |> Repo.one()
  end

  @doc "The office's review inbox: every collected review and private complaint, most recent first."
  def list_reviews(%Scope{active_account_id: account_id}) when not is_nil(account_id) do
    Review
    |> where([r], r.account_id == ^account_id)
    |> order_by([r], desc: r.inserted_at)
    |> preload([:job, :client, :cleaner])
    |> Repo.all()
  end

  @doc """
  Records the client's star rating and text for a requested review. A
  rating of 4-5 publishes the review; 3 or below routes it to a
  private complaint for the owner instead.
  """
  def submit_review(%Review{} = review, rating, text) when rating in 1..5 do
    review
    |> Review.submission_changeset(%{
      rating: rating,
      text: text,
      status: visibility_for_rating(rating),
      submitted_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  defp visibility_for_rating(rating) when rating <= 3, do: :private
  defp visibility_for_rating(_rating), do: :published
end
