defmodule CleanerCrmMcp.Tools.Clients.ListProperties do
  use CleanerCrmMcp.Tool, name: "list_properties"

  alias CleanerCrm.Clients
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    List a client's properties, ordered by address.
    Returns properties with access notes but never lockbox or alarm codes (see get_property_access). Errors when the client is not found.
    """

  @impl true
  def params,
    do: [%{name: "client_id", type: :string, required: true, description: "The client's id"}]

  @impl true
  def example,
    do: ~s|local ps = list_properties({ client_id = "..." })\nreturn ps[1].service_address|

  @impl true
  def call(%{"client_id" => id}, scope) do
    case Clients.fetch_client(scope, id) do
      {:ok, client} ->
        {:ok, scope |> Clients.list_properties(client) |> Enum.map(&Shape.property/1)}

      _ ->
        Shape.not_found("client")
    end
  end
end
