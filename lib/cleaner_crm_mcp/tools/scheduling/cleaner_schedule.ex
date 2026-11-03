defmodule CleanerCrmMcp.Tools.Scheduling.CleanerSchedule do
  use CleanerCrmMcp.Tool, name: "cleaner_schedule"

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    A cleaner's jobs and time off between two dates, soonest first.
    Defaults to today through 14 days out. Returns {cleaner, jobs, time_off}; jobs are shaped like list_jobs and exclude cancelled ones.
    Errors when the cleaner is not in this account.
    """

  @impl true
  def params,
    do: [
      %{name: "cleaner_id", type: :integer, required: true, description: "Cleaner id"},
      %{name: "from", type: :date, required: false, description: "Start date, default today"},
      %{
        name: "to",
        type: :date,
        required: false,
        description: "End date inclusive, default 14 days after from"
      }
    ]

  @impl true
  def example,
    do:
      ~s|local s = cleaner_schedule({ cleaner_id = 7, from = "2026-11-09", to = "2026-11-15" })\nreturn #s.jobs|

  @impl true
  def call(args, scope) do
    from = args["from"] || Date.utc_today()
    to = args["to"] || Date.add(from, 14)

    with {:ok, cleaner} <- Shape.find_cleaner(scope, args["cleaner_id"]) do
      jobs =
        scope
        |> Scheduling.search_jobs(%{cleaner_id: cleaner.id, from: from, to: to, limit: 200})
        |> Enum.map(&Shape.job/1)

      blocks =
        scope
        |> Scheduling.list_availability_blocks_between(cleaner.id, from, to)
        |> Enum.map(&Shape.block/1)

      {:ok, %{"cleaner" => Shape.cleaner(cleaner), "jobs" => jobs, "time_off" => blocks}}
    end
  end
end
