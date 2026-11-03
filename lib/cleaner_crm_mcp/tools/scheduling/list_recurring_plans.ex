defmodule CleanerCrmMcp.Tools.Scheduling.ListRecurringPlans do
  use CleanerCrmMcp.Tool, name: "list_recurring_plans"

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    List the account's recurring cleaning plans, by start date.
    Returns [{id, recurrence, start_date, occurrence_count, start_time, end_time, price, property, cleaner}].
    """

  @impl true
  def example, do: ~s|return list_recurring_plans()|

  @impl true
  def call(_args, scope),
    do: {:ok, scope |> Scheduling.list_recurring_plans() |> Enum.map(&Shape.plan/1)}
end
