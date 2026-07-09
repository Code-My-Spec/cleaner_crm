defmodule CleanerCrm.Notifications.ReminderSettings do
  @moduledoc """
  Per-account reminder timing: how many hours before an appointment the
  automatic reminder goes out. One row per account, created the first
  time the office saves the reminder settings form.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          lead_time_hours: integer(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "reminder_settings" do
    field :lead_time_hours, :integer, default: 24

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:lead_time_hours])
    |> validate_required([:lead_time_hours])
    |> validate_number(:lead_time_hours, greater_than: 0)
    |> unique_constraint(:account_id)
  end
end
