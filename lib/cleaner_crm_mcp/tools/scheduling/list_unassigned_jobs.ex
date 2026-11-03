defmodule CleanerCrmMcp.Tools.Scheduling.ListUnassignedJobs do
  use CleanerCrmMcp.Tool, name: "list_unassigned_jobs"

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    List scheduled jobs that have no cleaner yet, soonest first.
    Defaults to today onward. Returns jobs shaped like list_jobs (cancelled and completed jobs are left out).
    """

  @impl true
  def params,
    do: [
      %{name: "from", type: :date, required: false, description: "Earliest date, default today"},
      %{name: "to", type: :date, required: false, description: "Latest date, inclusive"}
    ]

  @impl true
  def example, do: ~s|return list_unassigned_jobs({ to = "2026-11-30" })|

  @impl true
  def call(args, scope) do
    filters =
      %{from: args["from"] || Date.utc_today(), unassigned_only: true, status: :scheduled}
      |> then(&if args["to"], do: Map.put(&1, :to, args["to"]), else: &1)

    {:ok, scope |> Scheduling.search_jobs(filters) |> Enum.map(&Shape.job/1)}
  end
end
