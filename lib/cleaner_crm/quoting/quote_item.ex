defmodule CleanerCrm.Quoting.QuoteItem do
  @moduledoc """
  A single priced line on a sent quote — a room type, the square
  footage, or the hours — along with the rate and amount frozen at the
  moment the quote was sent.

  Only ever created by `CleanerCrm.Quoting.send_quote/3`, alongside the
  `CleanerCrm.Quoting.Quote` it belongs to. Never updated afterward:
  this is the immutable record of what the client was actually quoted.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          quote_id: Ecto.UUID.t() | nil,
          description: String.t() | nil,
          quantity: integer() | nil,
          rate_cents: integer() | nil,
          amount_cents: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "quote_items" do
    field :description, :string
    field :quantity, :integer
    field :rate_cents, :integer
    field :amount_cents, :integer

    belongs_to :quote, CleanerCrm.Quoting.Quote, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(description quantity rate_cents amount_cents)a

  def changeset(quote_item, attrs) do
    quote_item
    |> cast(attrs, @fields)
    |> validate_required(@fields, message: "is required")
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:rate_cents, greater_than_or_equal_to: 0)
    |> validate_number(:amount_cents, greater_than_or_equal_to: 0)
    |> assoc_constraint(:quote)
  end
end
