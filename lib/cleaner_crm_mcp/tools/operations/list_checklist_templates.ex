defmodule CleanerCrmMcp.Tools.Operations.ListChecklistTemplates do
  use CleanerCrmMcp.Tool, name: "list_checklist_templates"

  alias CleanerCrm.Quality
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    List the account's cleaning checklist templates, by name.
    Returns a list of { id, name, property_id (nil = any property), items = [{ room, task, required }] }.
    """

  @impl true
  def example, do: ~s|local t = list_checklist_templates()\nreturn #t|

  @impl true
  def call(_args, scope),
    do: {:ok, scope |> Quality.list_checklist_templates() |> Enum.map(&Shape.template/1)}
end
