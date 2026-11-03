defmodule CleanerCrmMcp.Tools.Scheduling.GetCleaner do
  use CleanerCrmMcp.Tool, name: "get_cleaner"

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Get one cleaner with their upcoming jobs and time-off blocks.
    Returns {id, name, upcoming_jobs, time_off}; jobs are shaped like list_jobs. Errors when the cleaner is not in this account.
    """

  @impl true
  def params,
    do: [%{name: "cleaner_id", type: :integer, required: true, description: "Cleaner id"}]

  @impl true
  def example, do: ~s|local c = get_cleaner({ cleaner_id = 7 })\nreturn #c.upcoming_jobs|

  @impl true
  def call(args, scope) do
    with {:ok, cleaner} <- Shape.find_cleaner(scope, args["cleaner_id"]) do
      jobs =
        scope |> Scheduling.list_upcoming_jobs_for_cleaner(cleaner.id) |> Enum.map(&Shape.job/1)

      blocks =
        scope |> Scheduling.list_availability_blocks(cleaner.id) |> Enum.map(&Shape.block/1)

      {:ok,
       cleaner |> Shape.cleaner() |> Map.merge(%{"upcoming_jobs" => jobs, "time_off" => blocks})}
    end
  end
end
