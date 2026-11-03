defmodule CleanerCrmMcp.Tools.Scheduling.GetRecurringPlan do
  use CleanerCrmMcp.Tool, name: "get_recurring_plan"

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Get a recurring plan with the jobs it generated.
    Returns the plan (as in list_recurring_plans) plus "jobs", shaped like list_jobs (cancelled ones included). Errors when the plan is not found.
    """

  @impl true
  def params, do: [%{name: "id", type: :string, required: true, description: "Recurring plan id"}]

  @impl true
  def example, do: ~s|local p = get_recurring_plan({ id = id })\nreturn #p.jobs|

  @impl true
  def call(args, scope) do
    case Scheduling.fetch_recurring_plan(scope, args["id"]) do
      nil ->
        {:error, "no recurring plan with id #{args["id"]}"}

      plan ->
        jobs = scope |> Scheduling.list_plan_jobs(plan.id) |> Enum.map(&Shape.job/1)
        {:ok, plan |> Shape.plan() |> Map.put("jobs", jobs)}
    end
  end
end
