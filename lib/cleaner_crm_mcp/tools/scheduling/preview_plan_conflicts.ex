defmodule CleanerCrmMcp.Tools.Scheduling.PreviewPlanConflicts do
  use CleanerCrmMcp.Tool, name: "preview_plan_conflicts"

  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.RecurringPlan
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Preview a recurring plan's dates and conflicts without saving anything.
    Takes the same arguments as create_recurring_plan. Returns {dates, conflicts} where conflicts are [{index, date, reason}] against cleaner_id's time off and bookings (empty with no cleaner_id).
    Errors on an invalid recurrence or unknown property/cleaner.
    """

  @impl true
  def params, do: Shape.plan_params()

  @impl true
  def example,
    do:
      ~s|local r = preview_plan_conflicts({ property_id = prop.id, recurrence = "weekly", start_date = "2026-11-10", occurrence_count = 8, cleaner_id = 7 })\nreturn r.conflicts|

  @impl true
  def call(args, scope) do
    with {:ok, property} <- Shape.find_property(scope, args["property_id"]),
         {:ok, _} <- Shape.maybe_cleaner(scope, args["cleaner_id"]) do
      changeset =
        Scheduling.change_recurring_plan(
          scope,
          %RecurringPlan{},
          args |> Shape.plan_attrs() |> Map.put(:property_id, property.id)
        )

      if changeset.valid? do
        plan = Ecto.Changeset.apply_changes(changeset)
        dates = Scheduling.plan_dates(plan)

        {:ok,
         %{
           "dates" => Enum.map(dates, &Present.plain/1),
           "conflicts" => scope |> Scheduling.preview_conflicts(plan) |> Enum.map(&conflict/1)
         }}
      else
        {:error, changeset}
      end
    end
  end

  @doc false
  def conflict(%{index: i, date: d, reason: r}),
    do: %{"index" => i, "date" => Present.plain(d), "reason" => Shape.error(r)}
end
