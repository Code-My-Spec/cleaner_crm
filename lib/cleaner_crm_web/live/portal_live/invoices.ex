defmodule CleanerCrmWeb.PortalLive.Invoices do
  @moduledoc """
  Invoice list and payment: pay an open invoice with a new card
  (optionally saving it on file) and add a digital tip credited to
  the visit's assigned cleaner.

  Route: `/portal/invoices`, behind `CleanerCrmWeb.PortalAuth`'s
  magic-link session.

  ## Dependencies

  - `CleanerCrm.Portal`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Money
  alias CleanerCrm.Portal

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Invoices
        <:subtitle :if={@client.card_on_file}>
          <span data-test="card-on-file-badge" class="badge badge-success">Card on file</span>
        </:subtitle>
      </.header>

      <div
        :for={invoice <- @invoices}
        data-test={"invoice-row-#{invoice.id}"}
        class="card bg-base-100 border border-base-300 mb-3"
      >
        <div class="card-body">
          <div class="flex justify-between items-baseline">
            <span>{Money.format_cents(invoice.amount_cents)}</span>
            <span>{status_label(invoice.status)}</span>
          </div>

          <.button
            :if={invoice.status == :unpaid}
            data-test={"invoice-#{invoice.id}-pay-button"}
            phx-click="start_pay"
            phx-value-id={invoice.id}
          >
            Pay invoice
          </.button>

          <.form
            :if={@paying_invoice_id == invoice.id}
            for={@payment_form}
            data-test={"invoice-#{invoice.id}-payment-form"}
            phx-submit="pay"
            class="mt-2 space-y-2"
          >
            <input type="hidden" name="invoice_id" value={invoice.id} />
            <input type="hidden" name="payment[card_token]" value="pm_card_visa" />

            <label class="label">
              <input type="checkbox" name="payment[save_card]" value="true" />
              Save my card for next time
            </label>

            <.input field={@payment_form[:tip_cents]} type="number" label="Tip (cents)" />

            <.button type="submit" variant="primary">
              Submit payment
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    client = socket.assigns.client

    {:ok,
     socket
     |> assign(:page_title, "Invoices")
     |> assign(:client, client)
     |> assign(:invoices, Portal.list_invoices(client))
     |> assign(:paying_invoice_id, nil)
     |> assign(:payment_form, to_form(%{"tip_cents" => ""}, as: :payment))}
  end

  @impl true
  def handle_event("start_pay", %{"id" => id}, socket) do
    {:noreply, assign(socket, :paying_invoice_id, id)}
  end

  def handle_event("pay", %{"invoice_id" => id, "payment" => params}, socket) do
    client = socket.assigns.client
    invoice = Enum.find(socket.assigns.invoices, &(&1.id == id))

    case Portal.pay_invoice(client, invoice, params) do
      {:ok, _updated} ->
        {:noreply,
         socket
         |> assign(:client, Portal.get_client!(client.id))
         |> assign(:invoices, Portal.list_invoices(client))
         |> assign(:paying_invoice_id, nil)
         |> assign(:payment_form, to_form(%{"tip_cents" => ""}, as: :payment))}

      {:error, _reason} ->
        {:noreply,
         put_flash(socket, :error, "We couldn't process that payment. Please try again.")}
    end
  end

  defp status_label(:unpaid), do: "Unpaid"
  defp status_label(:charge_pending), do: "Charge Pending"
  defp status_label(:paid), do: "Paid"
end
