defmodule CleanerCrmMcp.Tools.Scheduling.CancelJob do
  use CleanerCrmMcp.Tool, name: "cancel_job", mutates: true

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Cancel a job. MUTATES: sets the job's status to "cancelled" (the row is kept, recorded in the audit trail).
    Returns the updated job shaped like list_jobs. Errors when the job is not found or is already cancelled.
    """

  @impl true
  def params, do: Shape.job_ref_params()

  @impl true
  def example, do: ~s|return cancel_job({ job_number = 1042 })|

  @impl true
  def call(args, scope) do
    with {:ok, job} <- Shape.find_job(scope, args),
         :ok <- not_cancelled(job),
         {:ok, updated} <- Scheduling.cancel_job(scope, job) do
      {:ok, Shape.reload_job(scope, updated)}
    end
  end

  defp not_cancelled(%{status: :cancelled, job_number: n}),
    do: {:error, "job #{n} is already cancelled"}

  defp not_cancelled(_), do: :ok
end
