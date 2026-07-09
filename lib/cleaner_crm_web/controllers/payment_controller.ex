defmodule CleanerCrmWeb.PaymentController do
  @moduledoc """
  Public payment-link pages: a client without a card on file reaches
  `/pay/:token` (the link `CleanerCrmWeb.InvoiceLive.Show` sends) to
  pay an invoice directly, no login required.

  ## Dependencies

  - `CleanerCrm.Billing`
  """

  use CleanerCrmWeb, :controller

  alias CleanerCrm.Billing

  def show(conn, %{"token" => token}) do
    case Billing.get_invoice_by_token(token) do
      nil -> render_not_found(conn)
      invoice -> render(conn, :show, invoice: invoice)
    end
  end

  def create(conn, %{"token" => token} = params) do
    case Billing.get_invoice_by_token(token) do
      nil -> render_not_found(conn)
      invoice -> submit_payment(conn, invoice, params)
    end
  end

  defp submit_payment(conn, invoice, params) do
    payment_method = Map.get(params, "payment_method")
    save_card = Map.get(params, "save_card") in ["true", "on"]

    case Billing.pay_via_link(invoice, payment_method) do
      {:ok, updated} ->
        render(conn, :paid, invoice: updated, save_card: save_card)

      {:error, reason} ->
        render(conn, :declined, invoice: invoice, message: decline_message(reason))
    end
  end

  # A genuine card decline gets its own message; anything else (a
  # misconfigured or unreachable payment provider) gets a neutral one —
  # never blaming the payer's card for what's actually our problem.
  defp decline_message(%{"code" => "card_declined"}) do
    "Your card was declined. Please try a different payment method or contact us for help."
  end

  defp decline_message(_reason) do
    "We couldn't process your payment right now. Please try again shortly or contact us for help."
  end

  defp render_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> render(:not_found)
  end
end
