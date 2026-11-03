defmodule CleanerCrmMcp.Tools.Clients.SearchClients do
  use CleanerCrmMcp.Tool, name: "search_clients"

  alias CleanerCrm.Clients
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Search clients by name, email or phone.
    Returns a list of clients (id, name, email, phone, preferred_channel, active, card_on_file), ordered by name.
    Phone matching ignores formatting: "(928) 598-4841", "9285984841" and "+19285984841" all match. With no query, lists clients.
    """

  @impl true
  def params,
    do: [
      %{
        name: "query",
        type: :string,
        required: false,
        description: "Text to find in name, email or phone"
      },
      %{
        name: "active",
        type: :boolean,
        required: false,
        description: "true = only active clients, false = only inactive; omit for both"
      },
      %{
        name: "limit",
        type: :integer,
        required: false,
        description: "Max results (default 25, max 200)"
      }
    ]

  @impl true
  def example,
    do:
      ~s|local found = search_clients({ query = "928-598-4841", active = true })\nreturn found[1] and found[1].name|

  @impl true
  def call(args, scope) do
    opts =
      [limit: Args.get(args, "limit", 25)] ++
        if(Map.has_key?(args, "active"), do: [active: args["active"]], else: [])

    {:ok,
     scope
     |> Clients.search_clients(Args.get(args, "query", ""), opts)
     |> Enum.map(&Shape.client/1)}
  end
end
