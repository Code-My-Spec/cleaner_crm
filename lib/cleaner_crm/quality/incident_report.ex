defmodule CleanerCrm.Quality.IncidentReport do
  @moduledoc """
  An immutable, timestamped report of damage, a missing item, or an
  unsafe condition, filed by the cleaner working the job. A photo is
  required for `:damage` and `:missing_item` — something the office
  needs to see to act on — but not `:unsafe_condition`, so a cleaner
  never has to stop and photograph a hazard before reporting it.

  Nothing here, or anywhere else in this context, updates or deletes
  a report once filed — see the migration's DB rules for the
  backstop, mirroring `CleanerCrm.Audit.AuditEntry`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias CleanerCrm.Quality.Photo

  @type type :: :damage | :missing_item | :unsafe_condition

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          job_id: Ecto.UUID.t() | nil,
          cleaner_id: integer() | nil,
          type: type() | nil,
          description: String.t() | nil,
          filed_at: DateTime.t() | nil,
          photos: [Photo.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil
        }

  @photo_required_types [:damage, :missing_item]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "incident_reports" do
    field :type, Ecto.Enum, values: [:damage, :missing_item, :unsafe_condition]
    field :description, :string
    field :filed_at, :utc_datetime_usec

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :job, CleanerCrm.Scheduling.Job, type: :binary_id
    belongs_to :cleaner, CleanerCrm.Users.User
    has_many :photos, Photo

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @doc """
  `has_photo?` reflects whether a photo accompanies this filing (the
  caller inserts it in the same transaction), since a report needing
  one is judged before any `Photo` row necessarily exists.
  """
  def changeset(report, attrs, has_photo?) do
    report
    |> cast(attrs, [:account_id, :job_id, :cleaner_id, :type, :description, :filed_at])
    |> validate_required([:account_id, :job_id, :cleaner_id, :type, :description, :filed_at])
    |> validate_photo_required(has_photo?)
  end

  defp validate_photo_required(changeset, true), do: changeset

  defp validate_photo_required(changeset, false) do
    case get_field(changeset, :type) do
      type when type in @photo_required_types ->
        add_error(changeset, :photo, "is required for this report type")

      _type ->
        changeset
    end
  end
end
