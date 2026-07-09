defmodule CleanerCrm.Billing.Invoice do
  @moduledoc """
  An invoice for a completed job.

  Per the payments-stripe ADR, `status` only ever advances on a Stripe
  webhook confirmation: charging a card or sending a payment link just
  submits a charge and moves the invoice to `:charge_pending`; only the
  webhook marks it `:paid`, and a declined charge reverts it to
  `:unpaid` so the owner can retry or fall back to a payment link.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type status :: :unpaid | :charge_pending | :paid

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          job_id: Ecto.UUID.t() | nil,
          amount_cents: integer() | nil,
          status: status(),
          stripe_payment_intent_id: String.t() | nil,
          payment_token: String.t() | nil,
          job: CleanerCrm.Scheduling.Job.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "invoices" do
    field :amount_cents, :integer
    field :amount, :decimal, virtual: true
    field :status, Ecto.Enum, values: [:unpaid, :charge_pending, :paid], default: :unpaid
    field :stripe_payment_intent_id, :string
    field :payment_token, :string

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :job, CleanerCrm.Scheduling.Job, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(job_id amount amount_cents status stripe_payment_intent_id payment_token)a

  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, @fields)
    |> validate_required([:job_id])
    |> put_amount_cents()
    # After `put_amount_cents/1`, not before — a caller supplying dollars
    # via `amount` has no `amount_cents` yet until that step runs.
    # Needed because `validate_number/3` below only runs against an
    # actual *change*, so an explicit `amount_cents: nil` (unchanged from
    # a fresh `%Invoice{}`'s own default) silently skips it and would
    # otherwise reach `amount_cents`'s NOT NULL column as a raised
    # constraint violation instead of a changeset error.
    |> validate_required([:amount_cents])
    |> validate_number(:amount_cents, greater_than_or_equal_to: 0)
    |> unique_constraint(:payment_token)
  end

  # `amount` arrives as dollars (a `Decimal`, matching the money-handling
  # ADR); rounded half-up and stored as `amount_cents` — the only column
  # ever persisted. Callers that already have cents (e.g. copying a job's
  # `agreed_price_cents`) pass `amount_cents` directly and skip this.
  defp put_amount_cents(changeset) do
    case get_change(changeset, :amount) do
      nil ->
        changeset

      %Decimal{} = amount ->
        cents = amount |> Decimal.mult(100) |> Decimal.round(0, :half_up) |> Decimal.to_integer()
        put_change(changeset, :amount_cents, cents)
    end
  end
end
