defmodule CleanerCrmMcp.Tools.Clients.UpdatePropertyAccess do
  use CleanerCrmMcp.Tool, name: "update_property_access", mutates: true

  alias CleanerCrm.Clients
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Set a property's lockbox and/or alarm code (SECRETS).
    Overwrites the stored encrypted codes you pass (an audit entry records which fields changed, not the values). Returns only has_lockbox_code / has_alarm_code flags, never the codes. Errors when the property is not found.
    """

  @impl true
  def params,
    do: [
      %{name: "property_id", type: :string, required: true, description: "The property's id"},
      %{name: "lockbox_code", type: :string, required: false, description: "New lockbox code"},
      %{name: "alarm_code", type: :string, required: false, description: "New alarm code"}
    ]

  @impl true
  def example,
    do: ~s|return update_property_access({ property_id = "...", lockbox_code = "4821" })|

  @impl true
  def call(%{"property_id" => id} = args, scope) do
    case Clients.fetch_property(scope, id) do
      {:ok, p} ->
        with {:ok, p} <-
               Clients.update_property(scope, p, Args.take(args, ~w(lockbox_code alarm_code))) do
          {:ok, Map.take(Shape.property(p), ["id", "has_lockbox_code", "has_alarm_code"])}
        end

      _ ->
        Shape.not_found("property")
    end
  end
end
