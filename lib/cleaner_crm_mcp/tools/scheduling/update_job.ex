defmodule CleanerCrmMcp.Tools.Scheduling.UpdateJob do
  use CleanerCrmMcp.Tool, name: "update_job", mutates: true

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Reschedule a job and/or change its price. MUTATES: changes only the fields you pass (date, start_time, end_time, price).
    Does NOT change the cleaner (use assign_cleaner) and does not re-check the cleaner's conflicts. Records the change in the audit trail.
    Returns the updated job shaped like list_jobs. Errors when the job is not found, nothing is given to change, or the times are invalid.
    """

  @impl true
  def params,
    do:
      Shape.job_ref_params() ++
        [
          %{name: "date", type: :date, required: false, description: "New date, YYYY-MM-DD"},
          %{name: "start_time", type: :time, required: false, description: "New start, HH:MM"},
          %{name: "end_time", type: :time, required: false, description: "New end, HH:MM"},
          %{name: "price", type: :number, required: false, description: "New price in dollars"}
        ]

  @impl true
  def example,
    do:
      ~s|return update_job({ job_number = 1042, date = "2026-11-12", start_time = "10:00", end_time = "12:00" })|

  @impl true
  def call(args, scope) do
    with {:ok, job} <- Shape.find_job(scope, args),
         {:ok, attrs} <- attrs(args),
         {:ok, updated} <- Scheduling.update_job(scope, job, attrs) do
      {:ok, Shape.reload_job(scope, updated)}
    end
  end

  defp attrs(args) do
    attrs =
      [{"date", :scheduled_date}, {"start_time", :start_time}, {"end_time", :end_time}]
      |> Enum.reduce(%{}, fn {key, field}, acc ->
        if args[key], do: Map.put(acc, field, args[key]), else: acc
      end)
      |> then(
        &if args["price"],
          do: Map.put(&1, :agreed_price_cents, Args.to_cents(args["price"])),
          else: &1
      )

    if attrs == %{},
      do: {:error, "nothing to change: give date, start_time, end_time or price"},
      else: {:ok, attrs}
  end
end
