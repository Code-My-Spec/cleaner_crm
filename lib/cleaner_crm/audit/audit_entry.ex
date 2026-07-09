defmodule CleanerCrm.Audit.AuditEntry do
  @moduledoc """
  An immutable record of actor, action, subject, and old/new values.

  Append-only: no update or delete function is exposed anywhere in the
  codebase, and the `audit_entries` table itself has DB rules blocking
  UPDATE/DELETE as defense in depth (see the migration that created it).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          actor_id: integer() | nil,
          system: boolean(),
          action: String.t() | nil,
          subject_type: String.t() | nil,
          subject_id: Ecto.UUID.t() | nil,
          old_value: map(),
          new_value: map(),
          inserted_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "audit_entries" do
    field :system, :boolean, default: false
    field :action, :string
    field :subject_type, :string
    field :subject_id, Ecto.UUID
    field :old_value, :map, default: %{}
    field :new_value, :map, default: %{}

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :actor, CleanerCrm.Users.User

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :account_id,
      :actor_id,
      :system,
      :action,
      :subject_type,
      :subject_id,
      :old_value,
      :new_value
    ])
    |> validate_required([:account_id, :action, :subject_type, :subject_id])
  end
end
