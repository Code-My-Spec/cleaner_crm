defmodule CleanerCrmMcp.Tools.Scheduling.GetJob do
  use CleanerCrmMcp.Tool, name: "get_job"

  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Get one job by job_number or id, with its client, property and cleaner.
    Returns the job shaped like list_jobs. Errors when neither is given or the account has no such job.
    """

  @impl true
  def params, do: Shape.job_ref_params()

  @impl true
  def example, do: ~s|local job = get_job({ job_number = 1042 })\nreturn job.client.name|

  @impl true
  def call(args, scope) do
    with {:ok, job} <- Shape.find_job(scope, args), do: {:ok, Shape.job(job)}
  end
end
