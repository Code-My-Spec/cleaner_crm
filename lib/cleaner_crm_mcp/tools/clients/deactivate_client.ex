defmodule CleanerCrmMcp.Tools.Clients.DeactivateClient do
  use CleanerCrmMcp.Tool, name: "deactivate_client", mutates: true

  alias CleanerCrm.Clients
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Deactivate (archive) a client; nothing is deleted.
    Sets active to false on the client. Returns the client. Errors when the client is not found.
    """

  @impl true
  def params,
    do: [%{name: "id", type: :string, required: true, description: "The client's id"}]

  @impl true
  def example, do: ~s|return deactivate_client({ id = "..." }).active|

  @impl true
  def call(%{"id" => id}, scope) do
    case Clients.fetch_client(scope, id) do
      {:ok, client} ->
        with {:ok, c} <- Clients.deactivate_client(scope, client), do: {:ok, Shape.client(c)}

      _ ->
        Shape.not_found("client")
    end
  end
end
