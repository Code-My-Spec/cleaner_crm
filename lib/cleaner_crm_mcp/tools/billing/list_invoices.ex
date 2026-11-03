defmodule CleanerCrmMcp.Tools.Billing.ListInvoices do
  use CleanerCrmMcp.Tool, name: "list_invoices"

  alias CleanerCrm.Billing
  alias CleanerCrmMcp.Tools.Billing.Shape

  @impl true
  def description,
    do: """
    List the account's invoices, newest first.
    Returns invoice summaries (id, status, amount, job_number, client {id, name}, inserted_at). status is unpaid, charge_pending or paid; from/to filter on the invoice's creation date, inclusive. Errors on an unknown status.
    """

  @impl true
  def params,
    do: [
      %{
        name: "status",
        type: :string,
        required: false,
        description: "unpaid, charge_pending or paid"
      },
      %{
        name: "client_id",
        type: :string,
        required: false,
        description: "Only invoices for this client's jobs"
      },
      %{
        name: "from",
        type: :date,
        required: false,
        description: "Created on or after, YYYY-MM-DD"
      },
      %{
        name: "to",
        type: :date,
        required: false,
        description: "Created on or before, YYYY-MM-DD"
      },
      %{name: "limit", type: :integer, required: false, description: "Max results (default 100)"}
    ]

  @impl true
  def example, do: ~s|local open = list_invoices({ status = "unpaid" })\nreturn #open|

  @impl true
  def call(args, scope) do
    with {:ok, status} <-
           Shape.parse_enum(args["status"], "status", ~w(unpaid charge_pending paid)),
         {:ok, client_id} <- Shape.check_uuid(args["client_id"], "client_id") do
      opts =
        Shape.compact(
          status: status,
          client_id: client_id,
          from: args["from"],
          to: args["to"],
          limit: args["limit"]
        )

      {:ok, scope |> Billing.list_invoices(opts) |> Enum.map(&Shape.invoice/1)}
    end
  end
end
