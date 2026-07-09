defmodule CleanerCrm.Scheduling.AvailabilityBlock do
  @moduledoc """
  A period when a cleaner is unavailable for assignment — a day off, or
  a partial-day block on a single date.

  `all_day: true` blocks the whole `date` regardless of `start_time`/
  `end_time` (which are ignored/nil in that case). Otherwise the block
  only covers `start_time..end_time` on `date`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          cleaner_id: integer() | nil,
          date: Date.t() | nil,
          all_day: boolean(),
          start_time: Time.t() | nil,
          end_time: Time.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "availability_blocks" do
    field :date, :date
    field :all_day, :boolean, default: false
    field :start_time, :time
    field :end_time, :time

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :cleaner, CleanerCrm.Users.User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(block, attrs) do
    block
    |> cast(attrs, [:cleaner_id, :date, :all_day, :start_time, :end_time])
    |> validate_required([:cleaner_id, :date])
    |> validate_partial_day_times()
  end

  defp validate_partial_day_times(changeset) do
    if get_field(changeset, :all_day) do
      changeset
    else
      validate_required(changeset, [:start_time, :end_time],
        message: "is required for a partial-day block"
      )
    end
  end
end
