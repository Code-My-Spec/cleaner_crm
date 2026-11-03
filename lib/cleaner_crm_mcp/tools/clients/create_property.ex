defmodule CleanerCrmMcp.Tools.Clients.CreateProperty do
  use CleanerCrmMcp.Tool, name: "create_property", mutates: true

  alias CleanerCrm.Clients
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Create a property (service address) for a client.
    Writes a new property. Returns it without access codes (set those with update_property_access). Errors when the client is not found in your account or the address is blank.
    """

  @impl true
  def params,
    do: [
      %{name: "client_id", type: :string, required: true, description: "The owning client's id"},
      %{
        name: "service_address",
        type: :string,
        required: true,
        description: "Street address of the property"
      },
      %{
        name: "entry_method",
        type: :string,
        required: false,
        description: "How cleaners get in, e.g. \"lockbox\", \"client home\""
      },
      %{name: "parking_notes", type: :string, required: false, description: "Where to park"},
      %{name: "pet_notes", type: :string, required: false, description: "Pets to know about"},
      %{
        name: "client_preferences",
        type: :string,
        required: false,
        description: "Cleaning preferences"
      },
      %{
        name: "emergency_contact_name",
        type: :string,
        required: false,
        description: "Emergency contact name"
      },
      %{
        name: "emergency_contact_phone",
        type: :string,
        required: false,
        description: "Emergency contact phone"
      }
    ]

  @impl true
  def example,
    do:
      ~s|return create_property({ client_id = "...", service_address = "12 Oak St, Sedona AZ", pet_notes = "Friendly dog" })|

  @impl true
  def call(args, scope) do
    attrs =
      Args.take(
        args,
        ~w(client_id service_address entry_method parking_notes pet_notes client_preferences emergency_contact_name emergency_contact_phone)
      )

    case Clients.fetch_client(scope, args["client_id"]) do
      {:ok, _} ->
        with {:ok, p} <- Clients.create_property(scope, attrs), do: {:ok, Shape.property(p)}

      _ ->
        Shape.not_found("client")
    end
  end
end
