defmodule CleanerCrmWeb.InvoiceLive.Index do
  @moduledoc """
  Lists the account's invoices with payment status — the office's
  billing queue.

  ## Dependencies

  - `CleanerCrm.Billing`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Billing
  alias CleanerCrm.Money

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Invoices
        <:subtitle>Billing queue for completed jobs</:subtitle>
      </.header>

      <p :if={Enum.empty?(@invoices)} class="text-center py-12 text-base-content/70">
        No invoices yet.
      </p>

      <.table :if={Enum.any?(@invoices)} id="invoices" rows={@invoices}>
        <:col :let={invoice} label="Client">{client_name(invoice)}</:col>
        <:col :let={invoice} label="Amount">{Money.format_cents(invoice.amount_cents)}</:col>
        <:col :let={invoice} label="Status">{status_label(invoice.status)}</:col>
        <:action :let={invoice}>
          <.link navigate={~p"/app/invoices/#{invoice}"} class="btn btn-sm btn-ghost">View</.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :invoices, Billing.list_invoices(socket.assigns.current_scope))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Invoices")}
  end

  defp client_name(%{job: %{client: %{name: name}}}), do: name
  defp client_name(_invoice), do: "—"

  defp status_label(:unpaid), do: "Unpaid"
  defp status_label(:charge_pending), do: "Charge Pending"
  defp status_label(:paid), do: "Paid"
end
