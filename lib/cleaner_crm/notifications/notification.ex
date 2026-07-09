defmodule CleanerCrm.Notifications.Notification do
  @moduledoc """
  An outbound message — a client appointment reminder or a cleaner
  schedule-change alert — with delivery status and acknowledgment
  tracking.

  `kind: :reminder` notifications carry a `client_id` and move through
  `:sent -> :delivered | :undelivered -> :confirmed | :reschedule_requested`.
  `kind: :schedule_change` notifications carry a `cleaner_id` instead
  and move through `:pending -> :acknowledged` (or `:escalated` when
  never acknowledged in time).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @kinds [:reminder, :schedule_change]
  @channels [:email, :sms, :push]
  @statuses [
    :pending,
    :sent,
    :delivered,
    :undelivered,
    :failed,
    :confirmed,
    :reschedule_requested,
    :acknowledged,
    :escalated
  ]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          client_id: Ecto.UUID.t() | nil,
          cleaner_id: integer() | nil,
          job_id: Ecto.UUID.t() | nil,
          kind: :reminder | :schedule_change,
          channel: :email | :sms | :push,
          status: atom(),
          token: String.t() | nil,
          provider_message_id: String.t() | nil,
          failure_reason: String.t() | nil,
          change_summary: String.t() | nil,
          pushed_at: DateTime.t() | nil,
          sent_at: DateTime.t() | nil,
          delivered_at: DateTime.t() | nil,
          confirmed_at: DateTime.t() | nil,
          reschedule_requested_at: DateTime.t() | nil,
          acknowledged_at: DateTime.t() | nil,
          escalated_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "notifications" do
    field :kind, Ecto.Enum, values: @kinds
    field :channel, Ecto.Enum, values: @channels
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :token, :string
    field :provider_message_id, :string
    field :failure_reason, :string
    field :change_summary, :string

    field :pushed_at, :utc_datetime_usec
    field :sent_at, :utc_datetime_usec
    field :delivered_at, :utc_datetime_usec
    field :confirmed_at, :utc_datetime_usec
    field :reschedule_requested_at, :utc_datetime_usec
    field :acknowledged_at, :utc_datetime_usec
    field :escalated_at, :utc_datetime_usec

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :client, CleanerCrm.Clients.Client, type: :binary_id
    belongs_to :cleaner, CleanerCrm.Users.User
    belongs_to :job, CleanerCrm.Scheduling.Job, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(client_id cleaner_id job_id kind channel status token provider_message_id
             failure_reason change_summary pushed_at sent_at delivered_at confirmed_at
             reschedule_requested_at acknowledged_at escalated_at)a

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, @fields)
    |> validate_required([:job_id, :kind, :channel, :token])
    |> unique_constraint(:token)
    |> foreign_key_constraint(:job_id)
  end

  def kinds, do: @kinds
  def channels, do: @channels
  def statuses, do: @statuses
end
