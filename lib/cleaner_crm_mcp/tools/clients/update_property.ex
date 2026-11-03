defmodule CleanerCrmMcp.Tools.Clients.UpdateProperty do
  use CleanerCrmMcp.Tool, name: "update_property", mutates: true

  alias CleanerCrm.Clients
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Update a property's address, entry method, parking/pet notes, preferences or emergency contact.
    Changes only the fields you pass. Does not touch lockbox/alarm codes (use update_property_access). Returns the property without codes. Errors when the property is not found.
    """

  @impl true
  def params,
    do: [
      %{name: "id", type: :string, required: true, description: "The property's id"},
      %{name: "service_address", type: :string, required: false, description: "New address"},
      %{name: "entry_method", type: :string, required: false, description: "How cleaners get in"},
      %{name: "parking_notes", type: :string, required: false, description: "Where to park"},
      %{name: "pet_notes", type: :string, required: false, description: "Pet notes"},
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
    do: ~s|return update_property({ id = "...", parking_notes = "Driveway, not street" })|

  @impl true
  def call(%{"id" => id} = args, scope) do
    attrs =
      Args.take(
        args,
        ~w(service_address entry_method parking_notes pet_notes client_preferences emergency_contact_name emergency_contact_phone)
      )

    case Clients.fetch_property(scope, id) do
      {:ok, p} ->
        with {:ok, p} <- Clients.update_property(scope, p, attrs), do: {:ok, Shape.property(p)}

      _ ->
        Shape.not_found("property")
    end
  end
end
