defmodule CleanerCrmMcp.Tools.Clients.ListLeads do
  use CleanerCrmMcp.Tool, name: "list_leads"

  alias CleanerCrm.Booking
  alias CleanerCrmMcp.Tools.Clients.Shape

  @statuses ~w(quoted accepted payment_pending payment_declined converted)

  @impl true
  def description,
    do: """
    List booking leads (instant-quote submissions), newest first.
    Returns leads with contact details, quote inputs, total (cents and dollars), status and links to the client/job once converted. Errors on an unknown status.
    Statuses: #{Enum.join(@statuses, ", ")}.
    """

  @impl true
  def params,
    do: [
      %{
        name: "status",
        type: :string,
        required: false,
        description: "Only leads with this status"
      },
      %{
        name: "limit",
        type: :integer,
        required: false,
        description: "Max results (default 25, max 200)"
      }
    ]

  @impl true
  def example, do: ~s|local leads = list_leads({ status = "payment_declined" })\nreturn #leads|

  @impl true
  def call(args, scope) do
    status = args["status"]

    if status && status not in @statuses do
      {:error, "unknown status `#{status}` (one of: #{Enum.join(@statuses, ", ")})"}
    else
      opts =
        [limit: Args.get(args, "limit", 25)] ++
          if(status, do: [status: String.to_existing_atom(status)], else: [])

      {:ok, scope |> Booking.list_leads(opts) |> Enum.map(&Shape.lead/1)}
    end
  end
end
