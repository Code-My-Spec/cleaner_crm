defmodule CleanerCrmMcp.Tools.Billing.GetPayment do
  use CleanerCrmMcp.Tool, name: "get_payment"

  alias CleanerCrm.Billing
  alias CleanerCrmMcp.Tools.Billing.Shape

  @impl true
  def description,
    do: """
    Get one payment attempt by id.
    Returns id, invoice_id, status, amount, provider, source and the Stripe payment intent id. Errors when the account has no such payment.
    """

  @impl true
  def params, do: [%{name: "id", type: :string, required: true, description: "The payment's id"}]

  @impl true
  def example, do: ~s|return get_payment({ id = "..." }).status|

  @impl true
  def call(%{"id" => id}, scope) do
    case Billing.fetch_payment(scope, id) do
      nil -> {:error, "no payment with id #{id}"}
      payment -> {:ok, Shape.payment(payment)}
    end
  end
end
