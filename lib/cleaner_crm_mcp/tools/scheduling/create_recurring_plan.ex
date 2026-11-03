defmodule CleanerCrmMcp.Tools.Scheduling.CreateRecurringPlan do
  use CleanerCrmMcp.Tool, name: "create_recurring_plan", mutates: true

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.PreviewPlanConflicts
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Create a recurring plan and its whole series of jobs. MUTATES: saves the plan and creates occurrence_count numbered jobs (assigned to cleaner_id if given).
    Conflicts with the preferred cleaner's time off or bookings do NOT block saving; they are returned in "conflicts" for review (run preview_plan_conflicts first to check).
    Returns the plan plus "jobs" (shaped like list_jobs) and "conflicts" [{index, date, reason}]. Errors on an invalid recurrence, count, or unknown property/cleaner.
    """

  @impl true
  def params, do: Shape.plan_params()

  @impl true
  def example,
    do:
      ~s|local p = create_recurring_plan({ property_id = prop.id, recurrence = "biweekly", start_date = "2026-11-10", occurrence_count = 6, price = 150 })\nreturn #p.jobs|

  @impl true
  def call(args, scope) do
    with {:ok, property} <- Shape.find_property(scope, args["property_id"]),
         {:ok, _} <- Shape.maybe_cleaner(scope, args["cleaner_id"]),
         {:ok, {plan, _jobs}} <-
           Scheduling.create_recurring_plan(
             scope,
             args |> Shape.plan_attrs() |> Map.put(:property_id, property.id)
           ) do
      plan = Scheduling.fetch_recurring_plan(scope, plan.id)
      jobs = scope |> Scheduling.list_plan_jobs(plan.id) |> Enum.map(&Shape.job/1)

      conflicts =
        scope |> Scheduling.preview_conflicts(plan) |> Enum.map(&PreviewPlanConflicts.conflict/1)

      {:ok, plan |> Shape.plan() |> Map.merge(%{"jobs" => jobs, "conflicts" => conflicts})}
    end
  end
end
