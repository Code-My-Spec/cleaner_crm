defmodule CleanerCrmMcp.Tools.Clients.GetProperty do
  use CleanerCrmMcp.Tool, name: "get_property"

  alias CleanerCrm.Clients
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Get one property with its entry method, parking/pet notes, preferences and emergency contact.
    Never includes lockbox or alarm codes: it only says whether they are set (has_lockbox_code, has_alarm_code). Use get_property_access for the codes.
    Errors when the property is not found.
    """

  @impl true
  def params,
    do: [%{name: "id", type: :string, required: true, description: "The property's id"}]

  @impl true
  def example, do: ~s|return get_property({ id = "..." }).parking_notes|

  @impl true
  def call(%{"id" => id}, scope) do
    case Clients.fetch_property(scope, id) do
      {:ok, p} -> {:ok, Shape.property(p)}
      _ -> Shape.not_found("property")
    end
  end
end
