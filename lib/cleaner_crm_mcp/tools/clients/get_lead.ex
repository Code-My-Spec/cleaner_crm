defmodule CleanerCrmMcp.Tools.Clients.GetLead do
  use CleanerCrmMcp.Tool, name: "get_lead"

  alias CleanerCrm.Booking
  alias CleanerCrmMcp.Tools.Clients.Shape

  @impl true
  def description,
    do: """
    Get one booking lead by id.
    Returns contact details, quote inputs, total, status, chosen slot and links to the client/property/job once converted. Errors when the lead is not found. Leads are converted only by the payment webhook; there is no tool to convert one.
    """

  @impl true
  def params,
    do: [%{name: "id", type: :string, required: true, description: "The lead's id"}]

  @impl true
  def example, do: ~s|return get_lead({ id = "..." }).status|

  @impl true
  def call(%{"id" => id}, scope) do
    case Booking.fetch_lead(scope, id) do
      {:ok, lead} -> {:ok, Shape.lead(lead)}
      _ -> Shape.not_found("lead")
    end
  end
end
