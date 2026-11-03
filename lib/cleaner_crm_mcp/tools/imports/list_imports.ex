defmodule CleanerCrmMcp.Tools.Imports.ListImports do
  use CleanerCrmMcp.Tool, name: "list_imports"

  alias CleanerCrm.Imports
  alias CleanerCrmMcp.Tools.Imports.Shared

  @impl true
  def description,
    do: """
    List recently imported rows (newest first), optionally of one kind.
    Each entry has kind, source_id, source_ref, crm_id (job_number for jobs) and a short summary of the raw row.
    """

  @impl true
  def params,
    do: [
      %{
        name: "kind",
        type: :string,
        required: false,
        description: "client, property, cleaner, job or quote"
      },
      %{name: "limit", type: :integer, required: false, description: "Max rows, default 20"}
    ]

  @impl true
  def example, do: ~s|local rows = list_imports({ kind = "job", limit = 5 })\nreturn #rows|

  @impl true
  def call(args, scope) do
    filters = [limit: args["limit"] || 20] ++ if(args["kind"], do: [kind: args["kind"]], else: [])
    {:ok, scope |> Imports.list_records(filters) |> Enum.map(&Shared.present(scope, &1))}
  end
end
