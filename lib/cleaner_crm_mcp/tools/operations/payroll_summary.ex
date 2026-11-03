defmodule CleanerCrmMcp.Tools.Operations.PayrollSummary do
  use CleanerCrmMcp.Tool, name: "payroll_summary"

  alias CleanerCrm.TimeTracking
  alias CleanerCrm.TimeTracking.Earnings
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    Per-cleaner earnings for a date range (default: the account's current Monday-Sunday pay period).
    Returns { from, to, ready_for_payroll, cleaners = [{ cleaner, jobs, worked_hours, total, total_cents, unresolved_jobs }], total, total_cents }.
    Jobs still clocked in or without a computable pay are counted in unresolved_jobs and withheld from totals; ready_for_payroll is false while any exist.
    Errors when from is after to.
    """

  @impl true
  def params,
    do: [
      %{
        name: "from",
        type: :date,
        description: "Period start, inclusive. Defaults to the current pay period start"
      },
      %{
        name: "to",
        type: :date,
        description: "Period end, inclusive. Defaults to the current pay period end"
      }
    ]

  @impl true
  def example,
    do:
      ~s|local p = payroll_summary({})\nfor _, c in ipairs(p.cleaners) do print(c.cleaner.name, c.total) end\nreturn p.total|

  @impl true
  def call(args, scope) do
    {default_from, default_to} = TimeTracking.current_pay_period(scope)
    from = Args.get(args, "from", default_from)
    to = Args.get(args, "to", default_to)

    with :ok <- Shape.check_range(from, to) do
      rows =
        scope
        |> TimeTracking.list_job_time_summaries({from, to})
        |> Enum.group_by(& &1.job.cleaner_id)
        |> Enum.map(fn {_id, summaries} -> cleaner_row(summaries) end)
        |> Enum.sort_by(&(&1["cleaner"]["name"] || ""))

      total = rows |> Enum.map(& &1["total_cents"]) |> Enum.sum()

      {:ok,
       %{
         "from" => Date.to_iso8601(from),
         "to" => Date.to_iso8601(to),
         "ready_for_payroll" => Enum.all?(rows, &(&1["unresolved_jobs"] == 0)),
         "cleaners" => rows
       }
       |> Map.merge(Present.money("total", total))}
    end
  end

  defp cleaner_row([first | _] = summaries) do
    {resolved, unresolved} = Enum.split_with(summaries, &(not &1.unresolved?))
    total = resolved |> Enum.map(& &1.cents) |> Enum.sum()

    seconds =
      for s <- resolved, e <- s.entries, e.clocked_out_at, reduce: 0 do
        acc -> acc + Earnings.worked_seconds(e)
      end

    Map.merge(
      %{
        "cleaner" => Shape.user(first.cleaner),
        "jobs" => length(resolved),
        "worked_hours" => Shape.hours(seconds),
        "unresolved_jobs" => length(unresolved)
      },
      Present.money("total", total)
    )
  end
end
