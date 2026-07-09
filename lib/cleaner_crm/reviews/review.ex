defmodule CleanerCrm.Reviews.Review do
  @moduledoc """
  A client's post-visit review: a star rating and free text, tied to
  the job, client, and (if one was assigned) cleaner it's about.

  Every review starts `:review_requested` — created the moment
  `CleanerCrm.Reviews.ReviewRequestWorker` sends its public link to the
  client — and moves to exactly one of `:published` (rating 4-5) or
  `:private` (rating 1-3, a complaint routed to the owner instead of a
  public posting) once the client submits it. One review per job: the
  `reviews.job_id` unique index is what
  `CleanerCrm.Reviews.ReviewRequestWorker`'s scan relies on to never
  send a second request for the same visit.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:review_requested, :published, :private]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          job_id: Ecto.UUID.t() | nil,
          client_id: Ecto.UUID.t() | nil,
          cleaner_id: integer() | nil,
          rating: integer() | nil,
          text: String.t() | nil,
          status: :review_requested | :published | :private,
          token: String.t() | nil,
          review_request_sent_at: DateTime.t() | nil,
          submitted_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "reviews" do
    field :rating, :integer
    field :text, :string
    field :status, Ecto.Enum, values: @statuses, default: :review_requested
    field :token, :string
    field :review_request_sent_at, :utc_datetime_usec
    field :submitted_at, :utc_datetime_usec

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :job, CleanerCrm.Scheduling.Job, type: :binary_id
    belongs_to :client, CleanerCrm.Clients.Client, type: :binary_id
    belongs_to :cleaner, CleanerCrm.Users.User

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(job_id client_id cleaner_id rating text status token
             review_request_sent_at submitted_at)a

  @doc "Builds or updates a review's request-side fields — the send itself, no rating yet."
  def changeset(review, attrs) do
    review
    |> cast(attrs, @fields)
    |> validate_required([:job_id, :client_id, :token])
    |> validate_inclusion(:rating, 1..5)
    |> unique_constraint(:token)
    |> unique_constraint(:job_id)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:client_id)
  end

  @doc "The client's submission: a star rating and optional text, routed by status to publish or private."
  def submission_changeset(review, attrs) do
    review
    |> cast(attrs, [:rating, :text, :status, :submitted_at])
    |> validate_required([:rating, :status, :submitted_at])
    |> validate_inclusion(:rating, 1..5)
  end

  def statuses, do: @statuses
end
