defmodule CleanerCrmMcp.Tools.Operations.ListNotifications do
  use CleanerCrmMcp.Tool, name: "list_notifications"

  alias CleanerCrm.Notifications
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    List the delivery log of client reminders and cleaner schedule-change alerts, newest first.
    Returns a list of { id, kind ("reminder" or "schedule_change"), channel, status, job_id, client, cleaner, sent_at, delivered_at, confirmed_at, reschedule_requested_at, acknowledged_at, failure_reason, change_summary }.
    """

  @impl true
  def params,
    do: [
      %{name: "kind", type: :string, description: "\"reminder\" or \"schedule_change\""},
      %{name: "job_number", type: :integer, description: "Only notifications for this job"},
      %{name: "limit", type: :integer, description: "Max results (default 50, max 500)"}
    ]

  @impl true
  def example, do: ~s|return list_notifications({ kind = "reminder", limit = 10 })|

  @impl true
  def call(args, scope) do
    kind = Args.get(args, "kind")

    with :ok <- check_kind(kind),
         {:ok, job_id} <- job_id(args, scope) do
      list =
        scope
        |> Notifications.list_notifications()
        |> Enum.filter(&(is_nil(kind) or Atom.to_string(&1.kind) == kind))
        |> Enum.filter(&(is_nil(job_id) or &1.job_id == job_id))
        |> Enum.take(Shape.limit(Args.get(args, "limit")))
        |> Enum.map(&Shape.notification/1)

      {:ok, list}
    end
  end

  defp check_kind(kind) when kind in [nil, "reminder", "schedule_change"], do: :ok
  defp check_kind(_), do: {:error, "`kind` must be \"reminder\" or \"schedule_change\""}

  defp job_id(args, scope) do
    case Args.get(args, "job_number") do
      nil -> {:ok, nil}
      number -> with {:ok, job} <- Shape.resolve_job(scope, number), do: {:ok, job.id}
    end
  end
end
