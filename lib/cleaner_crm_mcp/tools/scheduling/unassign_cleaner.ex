defmodule CleanerCrmMcp.Tools.Scheduling.UnassignCleaner do
  use CleanerCrmMcp.Tool, name: "unassign_cleaner", mutates: true

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Remove the cleaner from a job. MUTATES: clears the job's cleaner (never conflicts).
    Returns the updated job shaped like list_jobs. Errors when the job is not found.
    """

  @impl true
  def params, do: Shape.job_ref_params()

  @impl true
  def example, do: ~s|return unassign_cleaner({ job_number = 1042 })|

  @impl true
  def call(args, scope) do
    with {:ok, job} <- Shape.find_job(scope, args),
         {:ok, updated} <- Scheduling.assign_cleaner(scope, job, nil) do
      {:ok, Shape.reload_job(scope, updated)}
    end
  end
end
