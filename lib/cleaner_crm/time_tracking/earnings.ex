defmodule CleanerCrm.TimeTracking.Earnings do
  @moduledoc """
  Pure pay calculations — no scope, no `Repo`. Given a job and its
  time entries, this is the only place clocked time (or a fixed piece
  rate) turns into cents.
  """

  alias CleanerCrm.Scheduling.Job
  alias CleanerCrm.TimeTracking.TimeEntry

  @doc "Seconds between clock-in and clock-out. Only meaningful once resolved."
  def worked_seconds(%TimeEntry{clocked_in_at: in_at, clocked_out_at: out_at})
      when not is_nil(out_at) do
    DateTime.diff(out_at, in_at, :second)
  end

  @doc "Seconds elapsed so far on a still-open entry."
  def elapsed_seconds(%TimeEntry{clocked_out_at: nil, clocked_in_at: in_at}) do
    DateTime.diff(DateTime.utc_now(), in_at, :second)
  end

  @doc """
  Cents earned on a job given its (possibly empty) list of time
  entries: the flat piece rate regardless of time for a piece-rate job
  — shown even before the cleaner has started, since it doesn't
  depend on any entry existing — or the hourly rate times total
  resolved worked time. `nil` when an hourly job has no resolved
  entries yet, or a job carries neither pay type: there's nothing to
  compute pay from, and it must not be silently priced at $0.
  """
  def job_cents(%Job{pay_type: :piece_rate, piece_rate_cents: cents}, _entries)
      when is_integer(cents) do
    cents
  end

  def job_cents(%Job{pay_type: :hourly, hourly_rate_cents: rate}, entries)
      when is_integer(rate) and is_list(entries) and entries != [] do
    if Enum.all?(entries, &TimeEntry.resolved?/1) do
      entries |> Enum.map(&worked_seconds/1) |> Enum.sum() |> hourly_cents(rate)
    end
  end

  def job_cents(_job, _entries), do: nil

  defp hourly_cents(seconds, rate_cents) do
    Decimal.new(rate_cents)
    |> Decimal.mult(Decimal.div(Decimal.new(seconds), Decimal.new(3600)))
    |> Decimal.round(0, :half_up)
    |> Decimal.to_integer()
  end
end
