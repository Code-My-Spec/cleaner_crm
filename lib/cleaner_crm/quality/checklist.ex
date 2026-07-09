defmodule CleanerCrm.Quality.Checklist do
  @moduledoc """
  The instantiated checklist for a single job: its items, the
  owner's optional 1-5 rating, and the computed quality score (see
  `CleanerCrm.Quality.Scorecard`). Functions that need `items` for
  scoring or completion gating expect them preloaded, as returned by
  `CleanerCrm.Quality.get_checklist_for_job/2`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias CleanerCrm.Quality.ChecklistItem

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          job_id: Ecto.UUID.t() | nil,
          checklist_template_id: Ecto.UUID.t() | nil,
          owner_rating: integer() | nil,
          quality_score: float() | nil,
          completed_at: DateTime.t() | nil,
          items: [ChecklistItem.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "checklists" do
    field :owner_rating, :integer
    field :quality_score, :float
    field :completed_at, :utc_datetime_usec

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :job, CleanerCrm.Scheduling.Job, type: :binary_id
    belongs_to :checklist_template, CleanerCrm.Quality.ChecklistTemplate, type: :binary_id

    has_many :items, ChecklistItem, preload_order: [asc: :position]

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(checklist, attrs) do
    checklist
    |> cast(attrs, [
      :job_id,
      :checklist_template_id,
      :owner_rating,
      :quality_score,
      :completed_at
    ])
    |> validate_required([:job_id])
    |> validate_number(:owner_rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> unique_constraint(:job_id)
  end
end
