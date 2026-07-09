defmodule CleanerCrm.Quality.ChecklistItem do
  @moduledoc """
  A single room/task line on a job's checklist: its required flag,
  checked/skipped completion state, and the before/after photos
  attached to it as proof.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias CleanerCrm.Quality.Photo

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          checklist_id: Ecto.UUID.t() | nil,
          room: String.t() | nil,
          task: String.t() | nil,
          required: boolean(),
          checked: boolean(),
          checked_at: DateTime.t() | nil,
          skipped: boolean(),
          skip_reason: String.t() | nil,
          position: integer(),
          photos: [Photo.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "checklist_items" do
    field :room, :string
    field :task, :string
    field :required, :boolean, default: true
    field :checked, :boolean, default: false
    field :checked_at, :utc_datetime_usec
    field :skipped, :boolean, default: false
    field :skip_reason, :string
    field :position, :integer, default: 0

    belongs_to :checklist, CleanerCrm.Quality.Checklist, type: :binary_id
    has_many :photos, Photo

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:checklist_id, :room, :task, :required, :position])
    |> validate_required([:checklist_id, :task])
  end

  @doc "Checks the item off, stamping when, and clears any prior skip."
  def check_changeset(item) do
    change(item, checked: true, checked_at: DateTime.utc_now(), skipped: false, skip_reason: nil)
  end

  @doc "Reverts a checked item back to unchecked."
  def uncheck_changeset(item) do
    change(item, checked: false, checked_at: nil)
  end

  @doc "Marks a required item skipped, with a reason, instead of done."
  def skip_changeset(item, reason) do
    item
    |> change(skipped: true, skip_reason: reason, checked: false, checked_at: nil)
    |> validate_required([:skip_reason])
  end
end
