defmodule CleanerCrmMcp.Tools.Imports.FindImported do
  use CleanerCrmMcp.Tool, name: "find_imported"

  alias CleanerCrm.Imports
  alias CleanerCrmMcp.Tools.Imports.Shared

  @impl true
  def description,
    do: """
    Find which CRM record an imported (Maidily) row became, by its source id or source reference.
    Give kind (client, property, cleaner, job or quote) and source_id and/or source_ref (a Maidily job or invoice number).
    Returns a list of matches, each with crm_id (and job_number for jobs) plus a short summary of the raw row.
    Returns an empty list when nothing matches; errors when neither source_id nor source_ref is given.
    """

  @impl true
  def params,
    do: [
      %{
        name: "kind",
        type: :string,
        required: true,
        description: "client, property, cleaner, job or quote"
      },
      %{
        name: "source_id",
        type: :string,
        required: false,
        description: "The id in the source system"
      },
      %{
        name: "source_ref",
        type: :string,
        required: false,
        description: "The source's own reference, e.g. job/invoice number"
      },
      %{
        name: "source",
        type: :string,
        required: false,
        description: "Source system, default maidily"
      }
    ]

  @impl true
  def example,
    do:
      ~s|local m = find_imported({ kind = "job", source_ref = "20260520-77058" })\nreturn m[1].job_number|

  @impl true
  def call(args, scope) do
    if is_nil(args["source_id"]) and is_nil(args["source_ref"]) do
      {:error, "give source_id or source_ref"}
    else
      filters =
        [source_id: args["source_id"], source_ref: args["source_ref"], source: args["source"]]
        |> Enum.reject(fn {_, v} -> is_nil(v) end)

      {:ok,
       scope
       |> Imports.find_records(args["kind"], filters)
       |> Enum.map(&Shared.present(scope, &1))}
    end
  end
end
