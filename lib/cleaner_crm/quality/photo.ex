defmodule CleanerCrm.Quality.Photo do
  @moduledoc """
  A stored before/after (checklist proof) or incident photo, with
  offline-tolerant upload state.

  Per the file-storage ADR, uploads land in S3-compatible object
  storage via presigned URLs from the phone — a `Photo` row exists
  from the moment the cleaner picks the file (`:pending`, no
  `storage_key` yet) so a dropped connection just leaves it pending
  until the retry lands (`:uploaded`, `storage_key` set).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type kind :: :before | :after | :incident
  @type upload_state :: :pending | :uploaded

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          checklist_item_id: Ecto.UUID.t() | nil,
          incident_report_id: Ecto.UUID.t() | nil,
          kind: kind() | nil,
          upload_state: upload_state(),
          storage_key: String.t() | nil,
          captured_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "photos" do
    field :kind, Ecto.Enum, values: [:before, :after, :incident]
    field :upload_state, Ecto.Enum, values: [:pending, :uploaded], default: :pending
    field :storage_key, :string
    field :captured_at, :utc_datetime_usec

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :checklist_item, CleanerCrm.Quality.ChecklistItem, type: :binary_id
    belongs_to :incident_report, CleanerCrm.Quality.IncidentReport, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(photo, attrs) do
    photo
    |> cast(attrs, [
      :account_id,
      :checklist_item_id,
      :incident_report_id,
      :kind,
      :upload_state,
      :storage_key,
      :captured_at
    ])
    |> validate_required([:account_id, :kind])
    |> validate_one_owner()
  end

  @doc "Flips a pending photo to uploaded once its bytes land in storage."
  def uploaded_changeset(photo, storage_key) do
    change(photo, upload_state: :uploaded, storage_key: storage_key)
  end

  defp validate_one_owner(changeset) do
    case {get_field(changeset, :checklist_item_id), get_field(changeset, :incident_report_id)} do
      {nil, nil} ->
        add_error(changeset, :checklist_item_id, "or incident_report_id is required")

      {_id, nil} ->
        changeset

      {nil, _id} ->
        changeset

      {_checklist_item_id, _incident_report_id} ->
        add_error(changeset, :checklist_item_id, "and incident_report_id cannot both be set")
    end
  end
end
