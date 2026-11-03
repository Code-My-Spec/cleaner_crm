defmodule CleanerCrmMcp.Tools.Scheduling.ListJobs do
  use CleanerCrmMcp.Tool, name: "list_jobs"

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    List jobs in a date range, soonest first: the way to see who is assigned to what.
    Returns up to `limit` (default 50, max 200) jobs as {job_number, id, date, start_time, end_time, status, price, client, property, cleaner, recurring_plan_id}. Cancelled jobs are left out unless status = "cancelled".
    Errors on an invalid status or client_id.
    """

  @impl true
  def params,
    do: [
      %{
        name: "from",
        type: :date,
        required: false,
        description: "Earliest date, inclusive (YYYY-MM-DD)"
      },
      %{name: "to", type: :date, required: false, description: "Latest date, inclusive"},
      %{
        name: "cleaner_id",
        type: :integer,
        required: false,
        description: "Only jobs assigned to this cleaner"
      },
      %{
        name: "client_id",
        type: :string,
        required: false,
        description: "Only jobs for this client"
      },
      %{
        name: "status",
        type: :string,
        required: false,
        description: "scheduled | in_progress | completed | cancelled"
      },
      %{
        name: "unassigned_only",
        type: :boolean,
        required: false,
        description: "Only jobs with no cleaner"
      },
      %{
        name: "limit",
        type: :integer,
        required: false,
        description: "Max jobs, default 50, max 200"
      }
    ]

  @impl true
  def example,
    do:
      ~s|local jobs = list_jobs({ from = "2026-11-03", to = "2026-11-09" })\nfor _, j in ipairs(jobs) do print(j.job_number, j.date, j.cleaner and j.cleaner.name or "unassigned") end|

  @impl true
  def call(args, scope) do
    with {:ok, filters} <- filters(args) do
      {:ok, scope |> Scheduling.search_jobs(filters) |> Enum.map(&Shape.job/1)}
    end
  end

  @doc false
  def filters(args) do
    with {:ok, status} <- status(args["status"]),
         {:ok, client_id} <- client_id(args["client_id"]) do
      filters =
        %{
          from: args["from"],
          to: args["to"],
          cleaner_id: args["cleaner_id"],
          client_id: client_id,
          status: status,
          unassigned_only: args["unassigned_only"],
          limit: args["limit"]
        }
        |> Enum.reject(fn {_, v} -> is_nil(v) end)
        |> Map.new()

      {:ok, filters}
    end
  end

  defp status(nil), do: {:ok, nil}

  defp status(s) do
    if s in Shape.statuses(),
      do: {:ok, String.to_existing_atom(s)},
      else: {:error, "status must be one of: #{Enum.join(Shape.statuses(), ", ")}"}
  end

  defp client_id(nil), do: {:ok, nil}

  defp client_id(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> {:error, "client_id is not a valid id"}
    end
  end
end
