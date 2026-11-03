defmodule CleanerCrmMcp.Tools.Billing.GetInvoice do
  use CleanerCrmMcp.Tool, name: "get_invoice"

  alias CleanerCrm.Billing
  alias CleanerCrmMcp.Tools.Billing.Shape

  @impl true
  def description,
    do: """
    Get one invoice by id, with its payment attempts.
    Returns the invoice (status, amount, job_number, client) plus payments (each attempt's status and amount). Errors when the account has no such invoice.
    """

  @impl true
  def params, do: [%{name: "id", type: :string, required: true, description: "The invoice's id"}]

  @impl true
  def example, do: ~s|local inv = get_invoice({ id = "..." })\nreturn inv.status|

  @impl true
  def call(%{"id" => id}, scope) do
    case Billing.fetch_invoice(scope, id) do
      nil ->
        {:error, "no invoice with id #{id}"}

      invoice ->
        payments = Billing.list_payments(scope, invoice_id: invoice.id)

        {:ok,
         invoice |> Shape.invoice() |> Map.put("payments", Enum.map(payments, &Shape.payment/1))}
    end
  end
end
