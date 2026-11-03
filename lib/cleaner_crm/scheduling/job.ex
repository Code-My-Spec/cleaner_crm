defmodule CleanerCrm.Scheduling.Job do
  @moduledoc """
  A single scheduled visit: a property (or client), a time window, and
  an optional assigned cleaner.

  A job is either a one-off (`recurring_plan_id` is `nil`) or one
  occurrence materialized from a `RecurringPlan`'s cadence (see
  `CleanerCrm.Scheduling.Recurrence`). Both `client_id` and
  `property_id` are independently optional at the schema level — some
  callers (time tracking, quality, notifications) only ever have a
  client on hand, while the schedule board's own job form always
  carries a property.

  ## Status

  `:scheduled` (default) -> `:in_progress` -> `:completed`, or
  `:scheduled` -> `:cancelled`. Transitions beyond create/cancel belong
  to other contexts (time tracking clocks a job into `:in_progress`).

  ## Pay fields

  `pay_type`/`hourly_rate_cents`/`piece_rate_cents` describe what the
  *cleaner* earns for this job — as distinct from `agreed_price_cents`,
  what the *client* is charged. They live here rather than on a
  separate table for the same reason `agreed_price_cents` does: a
  job's pay arrangement is a one-off property of that job, read and
  written by `CleanerCrm.TimeTracking` rather than by Scheduling
  itself.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          client_id: Ecto.UUID.t() | nil,
          property_id: Ecto.UUID.t() | nil,
          cleaner_id: integer() | nil,
          recurring_plan_id: Ecto.UUID.t() | nil,
          scheduled_date: Date.t() | nil,
          start_time: Time.t() | nil,
          end_time: Time.t() | nil,
          status: :scheduled | :in_progress | :completed | :cancelled,
          agreed_price_cents: integer() | nil,
          pay_type: :hourly | :piece_rate | nil,
          hourly_rate_cents: integer() | nil,
          piece_rate_cents: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "jobs" do
    field :scheduled_date, :date
    field :start_time, :time
    field :end_time, :time

    field :status, Ecto.Enum,
      values: [:scheduled, :in_progress, :completed, :cancelled],
      default: :scheduled

    # The CRM's own reference for this job ("#1042"), per account. Assigned by

    # `CleanerCrm.Scheduling.create_job/3`; never cast from user input.

    field :job_number, :integer

    field :agreed_price_cents, :integer
    field :agreed_price, :decimal, virtual: true

    field :pay_type, Ecto.Enum, values: [:hourly, :piece_rate]
    field :hourly_rate_cents, :integer
    field :piece_rate_cents, :integer

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :client, CleanerCrm.Clients.Client, type: :binary_id
    belongs_to :property, CleanerCrm.Clients.Property, type: :binary_id
    belongs_to :cleaner, CleanerCrm.Users.User
    belongs_to :recurring_plan, CleanerCrm.Scheduling.RecurringPlan, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(client_id property_id cleaner_id recurring_plan_id scheduled_date
             start_time end_time status agreed_price_cents agreed_price
             pay_type hourly_rate_cents piece_rate_cents)a

  def changeset(job, attrs) do
    job
    |> cast(rename_date_key(attrs), @fields)
    |> validate_required([:scheduled_date, :start_time, :end_time])
    |> validate_time_order()
    |> put_agreed_price_cents()
  end

  # The board's own job form asks for a plain "date" — friendlier than
  # "scheduled date" — while some spex drive the same form with a
  # `scheduled_date` override instead (matching the schema field name
  # directly). The form carries a second, always-blank
  # `job[scheduled_date]` field purely as a landing pad for that
  # override key (`Phoenix.LiveViewTest.form/3` requires an override's
  # key to match a real field name in the form). Whichever one arrives
  # non-blank wins; `scheduled_date` takes precedence when both do,
  # since a still-blank landing pad means only `date` was ever touched.
  defp rename_date_key(%{"scheduled_date" => sd} = attrs) when sd not in [nil, ""],
    do: Map.delete(attrs, "date")

  defp rename_date_key(%{scheduled_date: sd} = attrs) when sd not in [nil, ""],
    do: Map.delete(attrs, :date)

  defp rename_date_key(%{"date" => date} = attrs),
    do: attrs |> Map.delete("date") |> Map.put("scheduled_date", date)

  defp rename_date_key(%{date: date} = attrs),
    do: attrs |> Map.delete(:date) |> Map.put(:scheduled_date, date)

  defp rename_date_key(attrs), do: attrs

  defp validate_time_order(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    if start_time && end_time && Time.compare(start_time, end_time) != :lt do
      add_error(changeset, :end_time, "must be after the start time")
    else
      changeset
    end
  end

  # `agreed_price` arrives as dollars (a `Decimal`, matching the
  # money-handling ADR's rate math); it is rounded half-up and stored
  # as `agreed_price_cents` — the only column ever persisted.
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
