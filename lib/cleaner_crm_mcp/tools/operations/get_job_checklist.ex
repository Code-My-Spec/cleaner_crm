defmodule CleanerCrmMcp.Tools.Operations.GetJobChecklist do
  use CleanerCrmMcp.Tool, name: "get_job_checklist"

  alias CleanerCrm.Quality
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    Get the checklist for a job, with progress and per-item status.
    Returns { job, completed, owner_rating, quality_score, checked, total, items = [{ room, task, required, checked, skipped, skip_reason, photos }] },
    or nil when the job has no checklist yet. Errors when job_number matches no job in this account.
    """

  @impl true
  def params,
    do: [%{name: "job_number", type: :integer, required: true, description: "The job's number"}]

  @impl true
  def example,
    do:
      ~s|local c = get_job_checklist({ job_number = 1042 })\nreturn c and c.checked .. "/" .. c.total|

  @impl true
  def call(%{"job_number" => number}, scope) do
    with {:ok, job} <- Shape.resolve_job(scope, number) do
      case Quality.get_checklist_for_job(scope, job) do
        nil ->
          {:ok, nil}

        checklist ->
          {checked, total} = Quality.progress(checklist)

          {:ok,
           %{
             "job" => Shape.job_ref(job),
             "completed" => not is_nil(checklist.completed_at),
             "completed_at" => Present.plain(checklist.completed_at),
             "owner_rating" => checklist.owner_rating,
             "quality_score" => checklist.quality_score,
             "checked" => checked,
             "total" => total,
             "items" => Enum.map(checklist.items, &Shape.checklist_item/1)
           }}
      end
    end
  end
end
