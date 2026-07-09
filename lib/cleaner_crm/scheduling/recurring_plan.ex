defmodule CleanerCrm.Scheduling.RecurringPlan do
  @moduledoc """
  A weekly/biweekly/monthly cadence for a property that materializes a
  series of `CleanerCrm.Scheduling.Job` rows (see
  `CleanerCrm.Scheduling.Recurrence`).

  `cleaner_id` is the client's *preferred* cleaner (story 846): every
  job generated from this plan defaults to this cleaner, and
  reassigning a single visit away from them is a warning, not a block.
  It is optional — a plan with no preferred cleaner generates
  unassigned jobs and never warns on reassignment.

  `start_time`/`end_time` default to a plain 9am-11am visit window;
  nothing in the plan form asks for these explicitly today, but every
  generated job needs a concrete time to run conflict detection
  against.

  `agreed_price_cents` is optional — a plan with no price generates
  visits with no price either (see
  `CleanerCrm.Scheduling.Recurrence.job_attrs/1`), and completing one of
  those visits skips invoice generation rather than crashing (see
  `CleanerCrm.Billing.generate_for_job/2`).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          property_id: Ecto.UUID.t() | nil,
          cleaner_id: integer() | nil,
          recurrence: :weekly | :biweekly | :monthly | nil,
          start_date: Date.t() | nil,
          occurrence_count: integer() | nil,
          start_time: Time.t() | nil,
          end_time: Time.t() | nil,
          agreed_price_cents: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "recurring_plans" do
    field :recurrence, Ecto.Enum, values: [:weekly, :biweekly, :monthly]
    field :start_date, :date
    field :occurrence_count, :integer
    field :start_time, :time, default: ~T[09:00:00]
    field :end_time, :time, default: ~T[11:00:00]
    field :agreed_price_cents, :integer
    field :agreed_price, :decimal, virtual: true

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :property, CleanerCrm.Clients.Property, type: :binary_id
    belongs_to :cleaner, CleanerCrm.Users.User

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(property_id cleaner_id recurrence start_date occurrence_count start_time end_time
             agreed_price_cents agreed_price)a

  @doc """
  Changeset for the fully-specified plan a save requires.
  """
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, @fields)
    |> validate_required([:property_id, :recurrence, :start_date, :occurrence_count])
    |> validate_number(:occurrence_count, greater_than: 0)
    |> put_agreed_price_cents()
  end

  @doc """
  Changeset for the live preview as the owner fills in the form —
  every field is optional so the conflict list can update incrementally
  as soon as enough of them are present, well before the plan is valid
  enough to save.
  """
  def preview_changeset(plan, attrs) do
    plan
    |> cast(attrs, @fields)
    |> put_agreed_price_cents()
  end

  # `agreed_price` arrives as dollars (a `Decimal`, matching the
  # money-handling ADR); rounded half-up and stored as
  # `agreed_price_cents` — the only column ever persisted. Mirrors
  # `CleanerCrm.Scheduling.Job.put_agreed_price_cents/1`.
  defp put_agreed_price_cents(changeset) do
    case get_change(changeset, :agreed_price) do
      nil ->
        changeset

      %Decimal{} = amount ->
        cents = amount |> Decimal.mult(100) |> Decimal.round(0, :half_up) |> Decimal.to_integer()
        put_change(changeset, :agreed_price_cents, cents)
    end
  end
end
