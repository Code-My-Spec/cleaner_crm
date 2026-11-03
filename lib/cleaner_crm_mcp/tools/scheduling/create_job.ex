defmodule CleanerCrmMcp.Tools.Scheduling.CreateJob do
  use CleanerCrmMcp.Tool, name: "create_job", mutates: true

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Create a one-off job for a property. MUTATES: adds a scheduled job and assigns the next job number.
    If cleaner_id is given the job is then assigned with a conflict check; on a conflict the job is still created, unassigned, and the result has "assignment_error".
    Returns the job shaped like list_jobs. Errors when the property or cleaner is not in this account or the times are invalid (end must be after start).
    """

  @impl true
  def params,
    do: [
      %{name: "property_id", type: :string, required: true, description: "Property id to clean"},
      %{name: "date", type: :date, required: true, description: "YYYY-MM-DD"},
      %{name: "start_time", type: :time, required: true, description: "HH:MM"},
      %{name: "end_time", type: :time, required: true, description: "HH:MM, after start_time"},
      %{name: "price", type: :number, required: false, description: "Agreed price in dollars"},
      %{name: "cleaner_id", type: :integer, required: false, description: "Cleaner to assign"}
    ]

  @impl true
  def example,
    do:
      ~s|local job = create_job({ property_id = p.id, date = "2026-11-10", start_time = "09:00", end_time = "11:30", price = 180 })\nreturn job.job_number|

  @impl true
  def call(args, scope) do
    with {:ok, property} <- Shape.find_property(scope, args["property_id"]),
         {:ok, cleaner} <- Shape.maybe_cleaner(scope, args["cleaner_id"]),
         attrs = attrs(args, property),
         {:ok, job} <- Scheduling.create_job(scope, attrs) do
      assign(scope, job, cleaner)
    end
  end

  defp attrs(args, property) do
    %{
      property_id: property.id,
      scheduled_date: args["date"],
      start_time: args["start_time"],
      end_time: args["end_time"]
    }
    |> then(
      &if args["price"],
        do: Map.put(&1, :agreed_price_cents, Args.to_cents(args["price"])),
        else: &1
    )
  end

  defp assign(scope, job, nil), do: {:ok, Shape.reload_job(scope, job)}

  defp assign(scope, job, cleaner) do
    case Scheduling.assign_cleaner(scope, job, cleaner.id) do
      {:ok, _} ->
        {:ok, Shape.reload_job(scope, job)}

      {:error, reason} ->
        {:ok, scope |> Shape.reload_job(job) |> Map.put("assignment_error", Shape.error(reason))}
    end
  end
end
