defmodule CleanerCrmMcp.Tools.Clients.GetPropertyAccess do
  use CleanerCrmMcp.Tool, name: "get_property_access"

  alias CleanerCrm.Clients
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Reveal a property's lockbox and alarm codes (SECRETS).
    This is the only tool that returns access codes; call it only when you actually need them and never repeat them in messages to clients. Returns property_id, service_address, entry_method, lockbox_code, alarm_code (nil when unset). Errors when the property is not found.
    """

  @impl true
  def params,
    do: [%{name: "property_id", type: :string, required: true, description: "The property's id"}]

  @impl true
  def example,
    do: ~s|local a = get_property_access({ property_id = "..." })\nreturn a.lockbox_code|

  @impl true
  def call(%{"property_id" => id}, scope) do
    case Clients.fetch_property(scope, id) do
      {:ok, p} -> {:ok, Shape.access(p)}
      _ -> Shape.not_found("property")
    end
  end
end
