defmodule CleanerCrm.TimeTracking.PayrollExport do
  @moduledoc """
  Builds the payroll CSV: one row per cleaner with total hours, job
  count, and gross pay for the period.

  Never called with an unresolved entry still in the set —
  `CleanerCrm.TimeTracking.export_pay_period_csv/2` refuses to build
  one until every job in the period has a resolved time entry.
  """

  alias CleanerCrm.Money
  alias CleanerCrm.TimeTracking.Earnings

  @header ["cleaner_email", "hours", "job_count", "gross_pay"]

  @doc """
  `job_summaries` is the list `CleanerCrm.TimeTracking.list_job_time_summaries/2`
  returns: one entry per job, each with its `cleaner`, `entries`, and
  earned `cents`.
  """
  def to_csv(job_summaries) do
    rows =
      job_summaries
      |> Enum.group_by(& &1.cleaner.id)
      |> Enum.map(fn {_cleaner_id, summaries} -> cleaner_row(summaries) end)

    [@header | rows]
    |> Enum.map_join("\n", &Enum.join(&1, ","))
    |> Kernel.<>("\n")
  end

  defp cleaner_row([%{cleaner: cleaner} | _] = summaries) do
    total_seconds =
      summaries
      |> Enum.flat_map(& &1.entries)
      |> Enum.map(&Earnings.worked_seconds/1)
      |> Enum.sum()

    hours = total_seconds |> Decimal.new() |> Decimal.div(Decimal.new(3600)) |> Decimal.round(2)
    gross_cents = summaries |> Enum.map(& &1.cents) |> Enum.sum()

    [
      cleaner.email,
      Decimal.to_string(hours),
      Integer.to_string(length(summaries)),
      Money.format_cents(gross_cents)
    ]
  end
end
