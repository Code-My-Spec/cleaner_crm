defmodule CleanerCrmMcp.Tools.Billing.ListPayments do
  use CleanerCrmMcp.Tool, name: "list_payments"

  alias CleanerCrm.Billing
  alias CleanerCrmMcp.Tools.Billing.Shape

  @impl true
  def description,
    do: """
    List payment attempts (card charges, payment links), newest first.
    Returns payments (id, invoice_id, status, amount, source, inserted_at). status is pending, succeeded or failed; a declined attempt and its retry both appear. Errors on an unknown status.
    """

  @impl true
  def params,
    do: [
      %{
        name: "status",
        type: :string,
        required: false,
        description: "pending, succeeded or failed"
      },
      %{
        name: "invoice_id",
        type: :string,
        required: false,
        description: "Only attempts against this invoice"
      },
      %{name: "from", type: :date, required: false, description: "On or after, YYYY-MM-DD"},
      %{name: "to", type: :date, required: false, description: "On or before, YYYY-MM-DD"},
      %{name: "limit", type: :integer, required: false, description: "Max results (default 100)"}
    ]

  @impl true
  def example, do: ~s|return list_payments({ status = "failed" })|

  @impl true
  def call(args, scope) do
    with {:ok, status} <- Shape.parse_enum(args["status"], "status", ~w(pending succeeded failed)),
         {:ok, invoice_id} <- Shape.check_uuid(args["invoice_id"], "invoice_id") do
      opts =
        Shape.compact(
          status: status,
          invoice_id: invoice_id,
          from: args["from"],
          to: args["to"],
          limit: args["limit"]
        )

      {:ok, scope |> Billing.list_payments(opts) |> Enum.map(&Shape.payment/1)}
    end
  end
end
