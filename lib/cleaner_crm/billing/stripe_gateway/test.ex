defmodule CleanerCrm.Billing.StripeGateway.Test do
  @moduledoc """
  Deterministic in-memory stand-in for Stripe, configured as the
  adapter for `CleanerCrm.Billing.StripeGateway` in `config/test.exs`.
  Every charge submits successfully — declines in this app are only
  ever driven by the webhook the spec posts directly to
  `POST /webhooks/stripe`, never by this adapter — and the webhook
  event is trusted as-is, since nothing in test ever signs one.
  """

  @behaviour CleanerCrm.Billing.StripeGateway

  @impl true
  def create_payment_intent(_params) do
    id = "pi_test_#{System.unique_integer([:positive])}"
    {:ok, %{id: id, status: "succeeded", client_secret: "#{id}_secret_test"}}
  end

  @impl true
  def verify_webhook_event(conn), do: {:ok, conn.params}
end
