defmodule CleanerCrm.Portal.CancellationPolicy do
  @moduledoc """
  Per-account reschedule/cancel policy: how much notice a client must
  give before a visit to cancel free of charge, the flat fee charged
  inside that window, the (typically higher) flat fee for a same-day
  cancellation, and the policy text shown to a client at booking.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          notice_window_hours: integer(),
          late_fee_cents: integer(),
          same_day_fee_cents: integer(),
          policy_text: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "cancellation_policies" do
    field :notice_window_hours, :integer, default: 24
    field :late_fee_cents, :integer, default: 0
    field :same_day_fee_cents, :integer, default: 0
    field :policy_text, :string

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(notice_window_hours late_fee_cents same_day_fee_cents policy_text)a

  def changeset(%__MODULE__{} = policy, attrs) do
    policy
    |> cast(attrs, @fields)
    |> validate_required([:notice_window_hours, :late_fee_cents, :same_day_fee_cents])
    |> validate_number(:notice_window_hours, greater_than_or_equal_to: 0)
    |> validate_number(:late_fee_cents, greater_than_or_equal_to: 0)
    |> validate_number(:same_day_fee_cents, greater_than_or_equal_to: 0)
    |> unique_constraint(:account_id)
  end
end
