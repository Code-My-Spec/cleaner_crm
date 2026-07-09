defmodule CleanerCrmWeb.InvoiceLive.Show do
  @moduledoc """
  Invoice detail: amount, payment status, proof-of-work from Quality
  for chargeback defense, and payment actions (charge the card on
  file, retry after a decline, or send a payment link).

  Per the payments-stripe ADR the invoice itself only ever changes
  status on a Stripe webhook confirmation — never synchronously from
  these buttons, so clicking "charge" here doesn't mark it paid.

  ## Dependencies

  - `CleanerCrm.Billing`
  - `CleanerCrm.Quality` (proof-of-work only)
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Billing
  alias CleanerCrm.Money
  alias CleanerCrm.Quality

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Invoice for {client_name(@invoice)}
        <:subtitle>
          {Money.format_cents(@invoice.amount_cents)} · {status_label(@invoice.status)}
        </:subtitle>
      </.header>

      <div class="flex gap-2 mb-6">
        <.button
          :if={can_charge_card?(@invoice, @client)}
          data-test="charge-card-button"
          phx-click="charge_card"
        >
          Charge card on file
        </.button>

        <.button
          :if={can_retry_charge?(@invoice, @client)}
          data-test="retry-charge-button"
          phx-click="charge_card"
        >
          Retry charge
        </.button>

        <.button
          :if={@invoice.status == :unpaid}
          data-test="send-payment-link-button"
          phx-click="send_payment_link"
        >
          Send payment link
        </.button>
      </div>

      <div :if={@payment_path} class="mb-6">
        <p>Share this payment link with the client:</p>
        <a href={@payment_path} data-test="payment-link">{@payment_path}</a>
      </div>

      <div class="mb-6">
        <.header>Proof of Work</.header>

        <p :if={@checklist_items == []} class="text-base-content/70">
          No completed checklist recorded.
        </p>

        <ul :if={@checklist_items != []} class="list">
          <li :for={item <- @checklist_items} class="list-row">
            {item.task}

            <img
              :for={photo <- item.photos}
              src={photo.storage_key}
              data-test="proof-of-work-photo"
              class="w-16 h-16 object-cover rounded"
            />
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    scope = socket.assigns.current_scope
    invoice = Billing.get_invoice!(scope, id)

    {:ok,
     socket
     |> assign(:invoice, invoice)
     |> assign(:client, invoice.job.client)
     |> assign(:page_title, "Invoice")
     |> assign(:payment_path, payment_path(invoice))
     |> assign(:checklist_items, checklist_items(scope, invoice.job))}
  end

  @impl true
  def handle_event("charge_card", _params, socket) do
    case Billing.charge_card(socket.assigns.current_scope, socket.assigns.invoice) do
      {:ok, invoice} ->
        {:noreply, assign(socket, :invoice, invoice)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, charge_error_message(reason))}
    end
  end

  def handle_event("send_payment_link", _params, socket) do
    {:ok, invoice} =
      Billing.create_payment_link(socket.assigns.current_scope, socket.assigns.invoice)

    {:noreply,
     socket
     |> assign(:invoice, invoice)
     |> assign(:payment_path, payment_path(invoice))}
  end

  defp payment_path(%{payment_token: nil}), do: nil
  defp payment_path(%{payment_token: token}), do: ~p"/pay/#{token}"

  defp client_name(%{job: %{client: %{name: name}}}), do: name
  defp client_name(_invoice), do: "—"

  defp can_charge_card?(invoice, client) do
    invoice.status == :unpaid and card_on_file?(client) and
      is_nil(invoice.stripe_payment_intent_id)
  end

  defp can_retry_charge?(invoice, client) do
    invoice.status == :unpaid and card_on_file?(client) and
      not is_nil(invoice.stripe_payment_intent_id)
  end

  defp card_on_file?(nil), do: false
  defp card_on_file?(client), do: client.card_on_file

  defp charge_error_message(:no_card_on_file), do: "This client has no card on file."

  defp charge_error_message(%{"code" => "card_declined"}) do
    "The card was declined. Try again or send a payment link instead."
  end

  defp charge_error_message(_reason) do
    "Unable to charge the card on file right now. Please try again shortly."
  end

  defp status_label(:unpaid), do: "Unpaid"
  defp status_label(:charge_pending), do: "Charge Pending"
  defp status_label(:paid), do: "Paid"

  defp checklist_items(scope, job) do
    case Quality.get_checklist_for_job(scope, job) do
      %{items: items} -> items
      nil -> []
    end
  end
end
