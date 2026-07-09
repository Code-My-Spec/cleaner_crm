defmodule CleanerCrm.Billing.Payment do
  @moduledoc """
  A single payment attempt against an invoice — the audit trail behind
  an invoice's current status. Kept separate from `Invoice` so a
  declined attempt and a later successful retry both stay on the
  record, instead of one row's history being overwritten.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type status :: :pending | :succeeded | :failed
  @type source :: String.t()

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          invoice_id: Ecto.UUID.t() | nil,
          amount_cents: integer() | nil,
          status: status(),
          provider: String.t(),
          stripe_payment_intent_id: String.t() | nil,
          source: source() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "payments" do
    field :amount_cents, :integer
    field :status, Ecto.Enum, values: [:pending, :succeeded, :failed], default: :pending
    field :provider, :string, default: "stripe"
    field :stripe_payment_intent_id, :string
    field :source, :string

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :invoice, CleanerCrm.Billing.Invoice, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(invoice_id amount_cents status provider stripe_payment_intent_id source)a

  def changeset(payment, attrs) do
    payment
    |> cast(attrs, @fields)
    |> validate_required([:invoice_id, :amount_cents, :status])
  end
end
