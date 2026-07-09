defmodule CleanerCrm.Clients.Client do
  @moduledoc """
  A paying customer with contact info and preferences.

  Scoped to an account: every client belongs to exactly one account and
  is only ever visible within that account.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          active: boolean(),
          card_on_file: boolean(),
          email: String.t() | nil,
          phone: String.t() | nil,
          preferred_channel: :email | :sms,
          properties: [CleanerCrm.Clients.Property.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "clients" do
    field :name, :string
    field :active, :boolean, default: true
    field :card_on_file, :boolean, default: false
    field :email, :string
    field :phone, :string
    field :preferred_channel, Ecto.Enum, values: [:email, :sms], default: :email

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    has_many :properties, CleanerCrm.Clients.Property

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(client, attrs) do
    client
    |> cast(attrs, [:name, :active, :card_on_file, :email, :phone, :preferred_channel])
    |> validate_required([:name], message: "is required")
    |> validate_length(:name, min: 1, max: 200)
  end
end
