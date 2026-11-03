defmodule CleanerCrmMcp.Tools.Clients.CreateClient do
  use CleanerCrmMcp.Tool, name: "create_client", mutates: true

  alias CleanerCrm.Clients
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Create a client in your account.
    Writes a new client record. Returns the created client. Errors with field messages when `name` is blank or a value is invalid.
    """

  @impl true
  def params,
    do: [
      %{name: "name", type: :string, required: true, description: "Client's full name"},
      %{name: "email", type: :string, required: false, description: "Email address"},
      %{name: "phone", type: :string, required: false, description: "Phone number, any format"},
      %{
        name: "preferred_channel",
        type: :string,
        required: false,
        description: "\"email\" or \"sms\" (default email)"
      }
    ]

  @impl true
  def example,
    do:
      ~s|return create_client({ name = "Dana Prescott", phone = "(928) 555-0100", preferred_channel = "sms" })|

  @impl true
  def call(args, scope) do
    attrs = Args.take(args, ~w(name email phone preferred_channel))

    with {:ok, client} <- Clients.create_client(scope, attrs), do: {:ok, Shape.client(client)}
  end
end
