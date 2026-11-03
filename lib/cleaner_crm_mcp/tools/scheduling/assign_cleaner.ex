defmodule CleanerCrmMcp.Tools.Scheduling.AssignCleaner do
  use CleanerCrmMcp.Tool, name: "assign_cleaner", mutates: true

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Assign (or reassign) a job to a cleaner. MUTATES: sets the job's cleaner after checking the cleaner's time off and other bookings.
    Returns the updated job shaped like list_jobs. Errors when the job or cleaner is not found, the cleaner has time off then, or already has an overlapping job.
    """

  @impl true
  def params,
    do:
      Shape.job_ref_params() ++
        [
          %{
            name: "cleaner_id",
            type: :integer,
            required: true,
            description: "Cleaner id (see list_cleaners)"
          }
        ]

  @impl true
  def example, do: ~s|return assign_cleaner({ job_number = 1042, cleaner_id = 7 })|

  @impl true
  def call(args, scope) do
    with {:ok, job} <- Shape.find_job(scope, args),
         {:ok, cleaner} <- Shape.find_cleaner(scope, args["cleaner_id"]),
         {:ok, updated} <- wrap(Scheduling.assign_cleaner(scope, job, cleaner.id)) do
      {:ok, Shape.reload_job(scope, updated)}
    end
  end

  defp wrap({:error, reason}) when is_atom(reason), do: {:error, Shape.error(reason)}
  defp wrap(other), do: other
end
