defmodule CleanerCrmMcp.Tools.Operations.ListIncidents do
  use CleanerCrmMcp.Tool, name: "list_incidents"

  alias CleanerCrm.Quality
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    List incident reports (damage, missing items, unsafe conditions), most recently filed first.
    Returns a list of { id, type, description, filed_at, job, cleaner, photo_count }.
    Errors when from is after to.
    """

  @impl true
  def params,
    do: [
      %{name: "cleaner_id", type: :integer, description: "Only incidents filed by this cleaner"},
      %{name: "from", type: :date, description: "Filed on or after this day (UTC)"},
      %{name: "to", type: :date, description: "Filed on or before this day (UTC)"},
      %{name: "limit", type: :integer, description: "Max results (default 50, max 500)"}
    ]

  @impl true
  def example, do: ~s|return list_incidents({ from = "2026-10-01" })|

  @impl true
  def call(args, scope) do
    from = Args.get(args, "from")
    to = Args.get(args, "to")
    cleaner_id = Args.get(args, "cleaner_id")

    with :ok <- Shape.check_range(from, to) do
      incidents =
        scope
        |> Quality.list_incident_reports()
        |> Enum.filter(&(is_nil(cleaner_id) or &1.cleaner_id == cleaner_id))
        |> Enum.filter(&Shape.in_range?(&1.filed_at, from, to))
        |> Enum.take(Shape.limit(Args.get(args, "limit")))
        |> Enum.map(&Shape.incident/1)

      {:ok, incidents}
    end
  end
end
