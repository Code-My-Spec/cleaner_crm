defmodule CleanerCrm.TimeTracking.TimeEntry do
  @moduledoc """
  A single clocked visit to a job: when the cleaner started, and when
  they stopped.

  A `nil` `clocked_out_at` means the entry is open. While the cleaner
  is still on site that's expected and transient; once it's the only
  thing standing between a job and payroll, it's the "missing
  clock-out" the owner must resolve (see
  `CleanerCrm.TimeTracking.resolve_clock_out/3`) before it counts
  toward anyone's pay.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          job_id: Ecto.UUID.t() | nil,
          cleaner_id: integer() | nil,
          clocked_in_at: DateTime.t() | nil,
          clocked_out_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "time_entries" do
    field :clocked_in_at, :utc_datetime_usec
    field :clocked_out_at, :utc_datetime_usec

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :job, CleanerCrm.Scheduling.Job, type: :binary_id
    belongs_to :cleaner, CleanerCrm.Users.User

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(clocked_in_at clocked_out_at)a

  def changeset(time_entry, attrs) do
    time_entry
    |> cast(attrs, @fields)
    |> validate_required([:clocked_in_at])
    |> validate_clock_out_after_clock_in()
  end

  defp validate_clock_out_after_clock_in(changeset) do
    case {get_field(changeset, :clocked_in_at), get_field(changeset, :clocked_out_at)} do
      {%DateTime{} = in_at, %DateTime{} = out_at} ->
        if DateTime.compare(out_at, in_at) == :gt,
          do: changeset,
          else: add_error(changeset, :clocked_out_at, "must be after the clock-in time")

      _ ->
        changeset
    end
  end

  @doc "An entry is resolved once it has a clock-out time."
  def resolved?(%__MODULE__{clocked_out_at: nil}), do: false
  def resolved?(%__MODULE__{}), do: true
end
