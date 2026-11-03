defmodule CleanerCrmMcp.Tools.Operations.ListAuditEntries do
  use CleanerCrmMcp.Tool, name: "list_audit_entries"

  alias CleanerCrm.Audit
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    The audit trail: who changed what and when, newest first.
    Returns a list of { id, at, action, subject_type, subject_id, system, actor, old_value, new_value }.
    Filter by record type (e.g. "Job"), a specific record id, a job number, or date range. Errors when from is after to or job_number matches no job.
    """

  @impl true
  def params,
    do: [
      %{name: "subject_type", type: :string, description: "Record type, e.g. \"Job\""},
      %{name: "subject_id", type: :string, description: "Id of the record the entry is about"},
      %{name: "job_number", type: :integer, description: "Shortcut: entries about this job"},
      %{name: "actor_id", type: :integer, description: "Only changes made by this user"},
      %{name: "from", type: :date, description: "On or after this day (UTC)"},
      %{name: "to", type: :date, description: "On or before this day (UTC)"},
      %{name: "limit", type: :integer, description: "Max results (default 50, max 500)"}
    ]

  @impl true
  def example, do: ~s|return list_audit_entries({ job_number = 1042, limit = 10 })|

  @impl true
  def call(args, scope) do
    from = Args.get(args, "from")
    to = Args.get(args, "to")

    with :ok <- Shape.check_range(from, to),
         {:ok, subject_id} <- subject_id(args, scope) do
      filters = %{
        subject_type: Args.get(args, "subject_type"),
        subject_id: subject_id,
        actor_id: Args.get(args, "actor_id"),
        date_from: from,
        date_to: to
      }

      entries =
        scope
        |> Audit.list_entries(filters)
        |> Enum.take(Shape.limit(Args.get(args, "limit")))
        |> Enum.map(&Shape.audit_entry/1)

      {:ok, entries}
    end
  end

  defp subject_id(args, scope) do
    case Args.get(args, "job_number") do
      nil -> {:ok, Args.get(args, "subject_id")}
      number -> with {:ok, job} <- Shape.resolve_job(scope, number), do: {:ok, job.id}
    end
  end
end
