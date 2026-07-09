defmodule CleanerCrm.Quoting.RateCard do
  @moduledoc """
  The account's configurable rates, one per pricing model.

  A single row per account (see `CleanerCrm.Quoting.get_or_create_rate_card/1`).
  A rate left blank means that pricing model isn't priced yet — quoting
  against it is refused until the owner sets a rate (see
  `CleanerCrm.Quoting.Pricing`).

  `weekly_discount_percent`/`biweekly_discount_percent`/`monthly_discount_percent`
  and `add_on_rates_cents` exist for the public instant-quote calculator
  (story 848, see `CleanerCrm.Booking.Pricing`) — a recurring frequency's
  discount off the one-time subtotal, and the configured price for each
  named add-on (e.g. `"inside_fridge" => 1500`). Unset (`nil`) means no
  discount; an add-on key missing from the map means it isn't priced
  yet, same "never guess a price" rule as the base rates.

  `minimum_visit_cents` is a floor `CleanerCrm.Booking.Pricing.summarize/2`
  clamps a lead's computed total up to when it's set (e.g. a 1-sqft
  per-sqft quote pricing out at $0.12) — `nil` means no floor.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          per_room_bedroom_rate_cents: integer() | nil,
          per_room_bathroom_rate_cents: integer() | nil,
          per_sqft_rate_cents: integer() | nil,
          hourly_rate_cents: integer() | nil,
          weekly_discount_percent: integer() | nil,
          biweekly_discount_percent: integer() | nil,
          monthly_discount_percent: integer() | nil,
          add_on_rates_cents: %{optional(String.t()) => integer()},
          minimum_visit_cents: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "rate_cards" do
    field :per_room_bedroom_rate_cents, :integer
    field :per_room_bathroom_rate_cents, :integer
    field :per_sqft_rate_cents, :integer
    field :hourly_rate_cents, :integer
    field :weekly_discount_percent, :integer
    field :biweekly_discount_percent, :integer
    field :monthly_discount_percent, :integer
    field :add_on_rates_cents, :map, default: %{}
    field :minimum_visit_cents, :integer

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @rate_fields ~w(per_room_bedroom_rate_cents per_room_bathroom_rate_cents
                  per_sqft_rate_cents hourly_rate_cents weekly_discount_percent
                  biweekly_discount_percent monthly_discount_percent add_on_rates_cents
                  minimum_visit_cents)a

  @discount_fields ~w(weekly_discount_percent biweekly_discount_percent monthly_discount_percent)a

  def changeset(rate_card, attrs) do
    rate_card
    |> cast(attrs, @rate_fields)
    |> validate_number(:per_room_bedroom_rate_cents, greater_than_or_equal_to: 0)
    |> validate_number(:per_room_bathroom_rate_cents, greater_than_or_equal_to: 0)
    |> validate_number(:per_sqft_rate_cents, greater_than_or_equal_to: 0)
    |> validate_number(:hourly_rate_cents, greater_than_or_equal_to: 0)
    |> validate_number(:minimum_visit_cents, greater_than_or_equal_to: 0)
    |> validate_discount_percents()
    |> validate_add_on_rates()
  end

  defp validate_discount_percents(changeset) do
    Enum.reduce(@discount_fields, changeset, fn field, changeset ->
      changeset
      |> validate_number(field, greater_than_or_equal_to: 0)
      |> validate_number(field, less_than_or_equal_to: 100)
    end)
  end

  # Every configured amount must be a non-negative integer number of
  # cents — the same shape every other rate on this card takes.
  defp validate_add_on_rates(changeset) do
    case get_change(changeset, :add_on_rates_cents) do
      nil ->
        changeset

      rates ->
        if Enum.all?(rates, fn {key, cents} -> is_binary(key) and valid_cents?(cents) end) do
          changeset
        else
          add_error(changeset, :add_on_rates_cents, "must map add-on names to whole cent amounts")
        end
    end
  end

  defp valid_cents?(cents), do: is_integer(cents) and cents >= 0
end
