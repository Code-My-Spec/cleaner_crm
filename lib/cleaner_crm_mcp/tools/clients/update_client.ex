defmodule CleanerCrmMcp.Tools.Clients.UpdateClient do
  use CleanerCrmMcp.Tool, name: "update_client", mutates: true

  alias CleanerCrm.Clients
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Update a client's name, email, phone, preferred channel or active flag.
    Changes only the fields you pass. Returns the updated client. Errors when the client is not found or a value is invalid.
    """

  @impl true
  def params,
    do: [
      %{name: "id", type: :string, required: true, description: "The client's id"},
      %{name: "name", type: :string, required: false, description: "New name"},
      %{name: "email", type: :string, required: false, description: "New email"},
      %{name: "phone", type: :string, required: false, description: "New phone"},
      %{
        name: "preferred_channel",
        type: :string,
        required: false,
        description: "\"email\" or \"sms\""
      },
      %{
        name: "active",
        type: :boolean,
        required: false,
        description: "false to archive, true to reactivate"
      }
    ]

  @impl true
  def example,
    do: ~s|return update_client({ id = "...", phone = "9285984841", preferred_channel = "sms" })|

  @impl true
  def call(%{"id" => id} = args, scope) do
    with {:ok, client} <- Clients.fetch_client(scope, id) |> nf("client"),
         {:ok, client} <-
           Clients.update_client(
             scope,
             client,
             Args.take(args, ~w(name email phone preferred_channel active))
           ) do
      {:ok, Shape.client(client)}
    end
  end

  defp nf({:ok, _} = ok, _), do: ok
  defp nf(_, what), do: Shape.not_found(what)
end
