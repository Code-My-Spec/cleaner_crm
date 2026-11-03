defmodule CleanerCrm.Imports.ImportRecord do
  @moduledoc """
  One row of data that came from another system (e.g. Maidily), and the CRM
  record it became.

  Keeps foreign ids (`source_id`), foreign references such as the source's own
  job number (`source_ref`) and the raw payload out of the domain tables.
  `target_id` is the id of the CRM record (a binary id, or a user id as a
  string), so one table covers every kind.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "import_records" do
    field :source, :string
    field :kind, :string
    field :source_id, :string
    field :source_ref, :string
    field :target_id, :string
    field :raw, :map

    belongs_to :account, CleanerCrm.Accounts.Account

    timestamps()
  end

  @fields ~w(source kind source_id source_ref target_id raw)a

  def changeset(record, attrs) do
    record
    |> cast(attrs, @fields)
    |> validate_required([:source, :kind, :source_id])
  end
end
