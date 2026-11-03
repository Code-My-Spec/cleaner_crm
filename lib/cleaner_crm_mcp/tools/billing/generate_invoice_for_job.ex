defmodule CleanerCrmMcp.Tools.Billing.GenerateInvoiceForJob do
  use CleanerCrmMcp.Tool, name: "generate_invoice_for_job", mutates: true

  alias CleanerCrm.{Billing, Scheduling}
  alias CleanerCrmMcp.Tools.Billing.Shape

  @impl true
  def description,
    do: """
    Create an unpaid invoice for a job at its agreed price.
    Writes one invoice row. It does NOT charge a card or send anything to the client. Returns the new invoice, or the existing one (with already_existed = true) if the job was already invoiced.
    Errors when the job is not found or has no agreed price.
    """

  @impl true
  def params,
    do: [
      %{
        name: "job_number",
        type: :integer,
        required: false,
        description: "The job's number, e.g. 1042"
      },
      %{name: "job_id", type: :string, required: false, description: "The job's id"}
    ]

  @impl true
  def example,
    do: ~s|local inv = generate_invoice_for_job({ job_number = 1042 })\nreturn inv.amount|

  @impl true
  def call(args, scope) do
    with {:ok, job} <- find_job(args, scope) do
      case Billing.get_invoice_for_job(scope, job.id) do
        nil -> generate(scope, job)
        existing -> {:ok, existing |> Shape.invoice() |> Map.put("already_existed", true)}
      end
    end
  end

  defp generate(scope, job) do
    case Billing.generate_for_job(scope, job) do
      {:ok, invoice} ->
        {:ok,
         scope
         |> Billing.fetch_invoice(invoice.id)
         |> Shape.invoice()
         |> Map.put("already_existed", false)}

      {:error, :no_price} ->
        {:error, "job ##{job.job_number} has no agreed price, so there is nothing to invoice"}

      {:error, other} ->
        {:error, other}
    end
  end

  defp find_job(%{"job_number" => number}, scope) do
    case Scheduling.get_job_by_number(scope, number) do
      nil -> {:error, "no job with number #{number}"}
      job -> {:ok, job}
    end
  end

  defp find_job(%{"job_id" => id}, scope) do
    case Billing.fetch_job(scope, id) do
      nil -> {:error, "no job with id #{id}"}
      job -> {:ok, job}
    end
  end

  defp find_job(_args, _scope), do: {:error, "give job_number or job_id"}
end
