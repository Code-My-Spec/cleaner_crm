defmodule CleanerCrm.Scheduling.Recurrence do
  @moduledoc """
  Generates the dates for a plan's series from its cadence.

  Project-local, calendar-date arithmetic (see the recurrence ADR) —
  no RRULE library, no virtual occurrences. `:weekly` steps 7 days,
  `:biweekly` 14, `:monthly` 28 (a fixed 4-week cadence, not a calendar
  month, so the weekday never drifts).

  TODO: the recurrence ADR calls for materializing against each
  account's IANA timezone (via `tzdata`) so visits stay pinned to local
  wall-clock across DST, plus a rolling 12-week horizon extended by a
  daily Oban job. Neither is implemented yet — dates here are naive
  and every plan is materialized in full up front, bounded only by its
  own `occurrence_count`.
  """

  alias CleanerCrm.Scheduling.RecurringPlan

  @step_days %{weekly: 7, biweekly: 14, every_3_weeks: 21, monthly: 28}

  @doc """
  Returns a list of `%{index:, date:}` maps, one per occurrence, in
  series order starting at 1. `nil` if the plan is missing any of the
  fields a series needs.
  """
  def occurrences(%RecurringPlan{
        recurrence: recurrence,
        start_date: %Date{} = start_date,
        occurrence_count: count
      })
      when recurrence in [:weekly, :biweekly, :every_3_weeks, :monthly] and is_integer(count) and
             count > 0 do
    step = Map.fetch!(@step_days, recurrence)

    for index <- 1..count do
      %{index: index, date: Date.add(start_date, (index - 1) * step)}
    end
  end

  def occurrences(_incomplete_plan), do: []

  @doc """
  Job attribute maps ready for `CleanerCrm.Scheduling.create_job/2`, one
  per occurrence. Carries the plan's `agreed_price_cents` (`nil` when
  the plan has none) onto every occurrence — `CleanerCrm.Billing`
  handles a `nil` price on job completion gracefully rather than
  crashing, but a priced plan should still price its own visits.
  """
  def job_attrs(%RecurringPlan{} = plan) do
    Enum.map(occurrences(plan), fn %{date: date} ->
      %{
        property_id: plan.property_id,
        cleaner_id: plan.cleaner_id,
        recurring_plan_id: plan.id,
        scheduled_date: date,
        start_time: plan.start_time,
        end_time: plan.end_time,
        agreed_price_cents: plan.agreed_price_cents
      }
    end)
  end
end
