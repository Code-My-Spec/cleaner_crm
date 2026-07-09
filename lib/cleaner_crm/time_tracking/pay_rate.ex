defmodule CleanerCrm.TimeTracking.PayRate do
  @moduledoc """
  A cleaner's default pay basis and rate.

  A job's own `pay_type`/`hourly_rate_cents`/`piece_rate_cents` (see
  `CleanerCrm.Scheduling.Job`) always take precedence when present —
  this is only the fallback a job-creation form would prefill from,
  one row per cleaner per account.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          cleaner_id: integer() | nil,
          basis: :hourly | :piece_rate | nil,
          rate_cents: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "pay_rates" do
    field :basis, Ecto.Enum, values: [:hourly, :piece_rate]
    field :rate_cents, :integer

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :cleaner, CleanerCrm.Users.User

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(cleaner_id basis rate_cents)a

  def changeset(pay_rate, attrs) do
    pay_rate
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_number(:rate_cents, greater_than: 0)
    |> unique_constraint([:account_id, :cleaner_id])
  end
end
