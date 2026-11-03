defmodule CleanerCrmMcp.Tools.Operations.ListTimeEntries do
  use CleanerCrmMcp.Tool, name: "list_time_entries"

  alias CleanerCrm.TimeTracking
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    List clock-in/clock-out time entries, newest first, optionally for one job, one cleaner and/or a date range.
    Returns a list of entries: id, job, cleaner, clocked_in_at, clocked_out_at, open (still clocked in), worked_hours (nil while open).
    Errors when job_number matches no job in this account, or from is after to.
    """

  @impl true
  def params,
    do: [
      %{name: "job_number", type: :integer, description: "Only entries for this job"},
      %{
        name: "cleaner_id",
        type: :integer,
        description: "Only entries for this cleaner (user id)"
      },
      %{name: "from", type: :date, description: "First clock-in day, inclusive (UTC)"},
      %{name: "to", type: :date, description: "Last clock-in day, inclusive (UTC)"},
      %{name: "limit", type: :integer, description: "Max entries (default 50, max 500)"}
    ]

  @impl true
  def example,
    do:
      ~s|local entries = list_time_entries({ from = "2026-11-02", to = "2026-11-08" })\nreturn #entries|

  @impl true
  def call(args, scope) do
    from = Args.get(args, "from")
    to = Args.get(args, "to")

    with :ok <- Shape.check_range(from, to),
         {:ok, job_id} <- job_id(args, scope) do
      filters = %{job_id: job_id, cleaner_id: Args.get(args, "cleaner_id"), from: from, to: to}

      entries =
        scope
        |> TimeTracking.list_time_entries(filters)
        |> Enum.take(Shape.limit(Args.get(args, "limit")))
        |> Enum.map(&Shape.time_entry/1)

      {:ok, entries}
    end
  end

  defp job_id(args, scope) do
    case Args.get(args, "job_number") do
      nil -> {:ok, nil}
      number -> with {:ok, job} <- Shape.resolve_job(scope, number), do: {:ok, job.id}
    end
  end
end
