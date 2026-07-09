defmodule CleanerCrm.Booking.Lead do
  @moduledoc """
  A public instant-quote submission (story 848/849): the property
  inputs and frequency/add-ons it was priced from, the price snapshot
  frozen at the moment contact info was captured, the client's contact
  details, and everything the acceptance flow (slot, cancellation-policy
  agreement, card) adds on top of it.

  ## Status

  `:quoted` — never actually persisted today (the calculator on `/book`
  prices a lead purely in memory, see `CleanerCrm.Booking.change_lead/2`)
  but kept as the schema default for a row that, in principle, exists
  before contact info locks it in.

  `:accepted` -> `:payment_pending` -> `:converted`, or `:payment_pending`
  -> `:payment_declined` (from which the client can retry). Only a
  Stripe webhook (`CleanerCrm.Booking.receive_payment_webhook/1`) ever
  moves a lead into `:converted` or `:payment_declined` — submitting
  the card just moves it to `:payment_pending`, per the same
  webhook-confirms-everything rule `CleanerCrm.Billing` follows for
  invoice payments.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type pricing_model :: :per_room | :per_sqft | :hourly
  @type frequency :: :one_time | :weekly | :biweekly | :monthly
  @type status :: :quoted | :accepted | :payment_pending | :payment_declined | :converted

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          pricing_model: pricing_model() | nil,
          bedroom_count: integer() | nil,
          bathroom_count: integer() | nil,
          square_feet: integer() | nil,
          hours: integer() | nil,
          frequency: frequency(),
          add_ons: [String.t()],
          total_cents: integer() | nil,
          status: status(),
          client_name: String.t() | nil,
          client_email: String.t() | nil,
          client_phone: String.t() | nil,
          acceptance_token: String.t() | nil,
          scheduled_date: Date.t() | nil,
          start_time: Time.t() | nil,
          end_time: Time.t() | nil,
          policy_agreed_at: DateTime.t() | nil,
          policy_agreed: boolean() | nil,
          stripe_payment_intent_id: String.t() | nil,
          client_id: Ecto.UUID.t() | nil,
          property_id: Ecto.UUID.t() | nil,
          job_id: Ecto.UUID.t() | nil,
          recurring_plan_id: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "leads" do
    field :pricing_model, Ecto.Enum, values: [:per_room, :per_sqft, :hourly]
    field :bedroom_count, :integer
    field :bathroom_count, :integer
    field :square_feet, :integer
    field :hours, :integer

    field :frequency, Ecto.Enum,
      values: [:one_time, :weekly, :biweekly, :monthly],
      default: :one_time

    field :add_ons, {:array, :string}, default: []
    field :total_cents, :integer

    field :status, Ecto.Enum,
      values: [:quoted, :accepted, :payment_pending, :payment_declined, :converted],
      default: :quoted

    field :client_name, :string
    field :client_email, :string
    field :client_phone, :string

    field :acceptance_token, :string

    field :scheduled_date, :date
    field :start_time, :time
    field :end_time, :time
    field :policy_agreed_at, :utc_datetime_usec
    # Not persisted as a boolean column — `confirm_booking/2` turns a
    # truthy submission into `policy_agreed_at` instead. Only exists so
    # the confirmation form has a real changeset field to bind its
    # agreement checkbox to.
    field :policy_agreed, :boolean, virtual: true, default: false

    field :stripe_payment_intent_id, :string

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :client, CleanerCrm.Clients.Client, type: :binary_id
    belongs_to :property, CleanerCrm.Clients.Property, type: :binary_id
    belongs_to :job, CleanerCrm.Scheduling.Job, type: :binary_id
    belongs_to :recurring_plan, CleanerCrm.Scheduling.RecurringPlan, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @quote_fields ~w(pricing_model bedroom_count bathroom_count square_feet hours frequency add_ons)a

  @doc """
  The calculator's own changeset — every pricing input, none of it
  required, so `CleanerCrm.Booking.Pricing` can price a live preview
  (via `Ecto.Changeset.apply_changes/1`) after every keystroke
  regardless of whether the changeset is complete yet.
  """
  def quote_changeset(lead, attrs) do
    lead
    |> cast(normalize_add_ons(attrs), @quote_fields)
    |> validate_number(:bedroom_count, greater_than_or_equal_to: 0)
    |> validate_number(:bathroom_count, greater_than_or_equal_to: 0)
    |> validate_number(:square_feet, greater_than_or_equal_to: 0)
    |> validate_number(:hours, greater_than_or_equal_to: 0)
  end

  @doc """
  The full changeset used once a lead is actually persisted: the
  calculator's inputs plus the price snapshot, contact details, and
  every field the acceptance flow fills in afterward.
  """
  def changeset(lead, attrs) do
    lead
    |> quote_changeset(attrs)
    |> cast(attrs, [
      :total_cents,
      :status,
      :client_name,
      :client_email,
      :client_phone,
      :acceptance_token,
      :scheduled_date,
      :start_time,
      :end_time,
      :policy_agreed_at,
      :stripe_payment_intent_id,
      :client_id,
      :property_id,
      :job_id,
      :recurring_plan_id
    ])
    |> validate_required([:client_name, :client_email, :client_phone], message: "is required")
    |> validate_number(:total_cents, greater_than_or_equal_to: 0)
    |> unique_constraint(:acceptance_token)
  end

  @doc """
  The slot-selection step's own changeset — the chosen date and start
  time, required and rejected outright if already in the past (issue
  4e985412: this form accepted any date, including years-old ones,
  with zero validation). `now` defaults to the real clock but takes an
  override so callers can test the boundary without sleeping.
  """
  def slot_changeset(lead, attrs, now \\ DateTime.utc_now()) do
    lead
    |> cast(attrs, [:scheduled_date, :start_time])
    |> validate_required([:scheduled_date, :start_time], message: "is required")
    |> validate_slot_in_future(now)
  end

  @doc "The confirmation step's own changeset — the policy-agreement checkbox."
  def confirmation_changeset(lead, attrs) do
    cast(lead, attrs, [:policy_agreed])
  end

  @doc """
  Whether a lead's `scheduled_date`/`start_time` are still ahead of
  `now` (defaulting to the real clock) — today counts only if
  `start_time` hasn't passed yet. `false` for either field unset.

  The single source of truth behind two checks: `slot_changeset/3`'s
  own validation above (the form-level guard), and
  `CleanerCrm.Booking.confirm_booking/3`'s defense-in-depth re-check
  right before a card is charged — a slot picked as "later today" can
  go stale by the time the client actually submits payment, the same
  reason `CleanerCrm.Scheduling.slot_available?/4` gets re-checked
  there too.
  """
  @spec slot_in_future?(t(), DateTime.t()) :: boolean()
  def slot_in_future?(lead, now \\ DateTime.utc_now())

  def slot_in_future?(%__MODULE__{scheduled_date: nil}, _now), do: false
  def slot_in_future?(%__MODULE__{start_time: nil}, _now), do: false

  def slot_in_future?(%__MODULE__{scheduled_date: date, start_time: start_time}, now) do
    case Date.compare(date, DateTime.to_date(now)) do
      :gt -> true
      :lt -> false
      :eq -> Time.compare(start_time, DateTime.to_time(now)) == :gt
    end
  end

  defp validate_slot_in_future(changeset, now) do
    date = get_field(changeset, :scheduled_date)
    start_time = get_field(changeset, :start_time)

    cond do
      is_nil(date) or is_nil(start_time) ->
        changeset

      slot_in_future?(%__MODULE__{scheduled_date: date, start_time: start_time}, now) ->
        changeset

      Date.compare(date, DateTime.to_date(now)) == :lt ->
        add_error(changeset, :scheduled_date, "must be today or later")

      true ->
        add_error(changeset, :start_time, "must be later than the current time")
    end
  end

  # A hidden fallback input keeps `quote[add_ons][]` present in the
  # form even with every add-on unchecked (so unchecking the last one
  # actually clears it) at the cost of always submitting one blank
  # entry alongside any real ones — dropped here rather than left for
  # every caller to filter.
  defp normalize_add_ons(%{"add_ons" => list} = attrs) when is_list(list),
    do: %{attrs | "add_ons" => Enum.reject(list, &(&1 in [nil, ""]))}

  defp normalize_add_ons(attrs), do: attrs
end
