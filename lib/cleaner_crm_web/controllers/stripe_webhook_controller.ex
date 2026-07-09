defmodule CleanerCrmWeb.StripeWebhookController do
  @moduledoc """
  Public Stripe webhook endpoint (`POST /webhooks/stripe`) — the only
  place an invoice's or a booking lead's payment status ever changes
  from a pending charge, per the payments-stripe ADR. Verification
  (real signature check in production, trusted as-is in test) happens
  inside `CleanerCrm.Billing.receive_webhook/1` and
  `CleanerCrm.Booking.receive_payment_webhook/1`, so this controller
  never branches on anything but their results.

  Both contexts share the one webhook URL Stripe is configured with —
  `CleanerCrm.Billing` owns it, so a booking's charge is only tried
  once its event doesn't match one of Billing's own invoices.

  ## Dependencies

  - `CleanerCrm.Billing`
  - `CleanerCrm.Booking`
  """

  use CleanerCrmWeb, :controller

  alias CleanerCrm.Billing
  alias CleanerCrm.Booking

  def create(conn, _params) do
    case Billing.receive_webhook(conn) do
      {:ok, _result} ->
        json(conn, %{received: true})

      {:error, :invoice_not_found} ->
        create_for_booking(conn)

      {:error, _reason} ->
        error_response(conn)
    end
  end

  defp create_for_booking(conn) do
    case Booking.receive_payment_webhook(conn) do
      {:ok, _result} -> json(conn, %{received: true})
      {:error, _reason} -> error_response(conn)
    end
  end

  defp error_response(conn) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid_signature"})
  end
end
