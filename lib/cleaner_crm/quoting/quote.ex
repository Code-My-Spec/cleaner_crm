defmodule CleanerCrm.Quoting.Quote do
  @moduledoc """
  A priced proposal for a client, priced by exactly one pricing model
  at a time (`:per_room`, `:per_sqft`, or `:hourly`).

  `client_id` links an existing `CleanerCrm.Clients.Client` when the
  owner already has one on file; `client_name`/`client_phone` carry a
  lead's details when quoting someone who isn't a client yet (e.g. a
  phone lead quoted before any site visit).

  A quote is built up client-side (in `CleanerCrmWeb.QuoteLive.Builder`)
  and only ever persisted at the moment it's sent — see
  `CleanerCrm.Quoting.send_quote/3`. Once `:sent`, its `total_cents` and
  `CleanerCrm.Quoting.QuoteItem` line items are frozen: later rate-card
  changes never alter it.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type pricing_model :: :per_room | :per_sqft | :hourly
  @type status :: :draft | :sent

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          client_id: Ecto.UUID.t() | nil,
          client_name: String.t() | nil,
          client_phone: String.t() | nil,
          pricing_model: pricing_model() | nil,
          bedroom_count: integer() | nil,
          bathroom_count: integer() | nil,
          square_feet: integer() | nil,
          hours: integer() | nil,
          status: status(),
          total_cents: integer(),
          sent_at: DateTime.t() | nil,
          quote_items: [CleanerCrm.Quoting.QuoteItem.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "quotes" do
    field :client_name, :string
    field :client_phone, :string
    field :pricing_model, Ecto.Enum, values: [:per_room, :per_sqft, :hourly]
    field :bedroom_count, :integer
    field :bathroom_count, :integer
    field :square_feet, :integer
    field :hours, :integer
    field :status, Ecto.Enum, values: [:draft, :sent], default: :draft
    field :total_cents, :integer, default: 0
    field :sent_at, :utc_datetime_usec

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :client, CleanerCrm.Clients.Client, type: :binary_id
    has_many :quote_items, CleanerCrm.Quoting.QuoteItem

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(client_id client_name client_phone pricing_model bedroom_count
             bathroom_count square_feet hours status total_cents sent_at)a

  def changeset(quote, attrs) do
    quote
    |> cast(blank_client_id_to_nil(attrs), @fields)
    |> validate_number(:bedroom_count, greater_than_or_equal_to: 0)
    |> validate_number(:bathroom_count, greater_than_or_equal_to: 0)
    |> validate_number(:square_feet, greater_than_or_equal_to: 0)
    |> validate_number(:hours, greater_than_or_equal_to: 0)
    |> validate_number(:total_cents, greater_than_or_equal_to: 0)
    |> assoc_constraint(:client)
  end

  defp blank_client_id_to_nil(%{"client_id" => ""} = attrs), do: %{attrs | "client_id" => nil}
  defp blank_client_id_to_nil(attrs), do: attrs
end
