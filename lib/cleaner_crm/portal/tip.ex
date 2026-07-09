defmodule CleanerCrm.Portal.Tip do
  @moduledoc """
  A digital tip a client adds at payment time, credited to the
  cleaner who worked the invoice's visit (`nil` if that visit has no
  assigned cleaner — the tip is still collected, it just has no
  earnings to show up in) and linked to the Stripe charge it rode in
  on.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          invoice_id: Ecto.UUID.t() | nil,
          cleaner_id: integer() | nil,
          amount_cents: integer() | nil,
          stripe_payment_intent_id: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "tips" do
    field :amount_cents, :integer
    field :stripe_payment_intent_id, :string

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :invoice, CleanerCrm.Billing.Invoice, type: :binary_id
    belongs_to :cleaner, CleanerCrm.Users.User

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(account_id invoice_id cleaner_id amount_cents stripe_payment_intent_id)a

  def changeset(%__MODULE__{} = tip, attrs) do
    tip
    |> cast(attrs, @fields)
    |> validate_required([:account_id, :invoice_id, :amount_cents])
    |> validate_number(:amount_cents, greater_than: 0)
  end
end
