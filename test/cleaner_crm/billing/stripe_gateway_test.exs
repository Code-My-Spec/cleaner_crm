defmodule CleanerCrm.Billing.StripeGatewayTest do
  @moduledoc """
  Guards the Live adapter's graceful-degradation behavior: a deploy
  missing `STRIPE_SECRET_KEY`/`STRIPE_WEBHOOK_SECRET` (any dev machine,
  by design — see `config/dev.exs`) must get `{:error, _}` back from
  every call, never a raised exception that would crash the calling
  LiveView or turn a public controller response into a raw 500.
  """

  use ExUnit.Case, async: false

  alias CleanerCrm.Billing.StripeGateway.Live

  setup do
    original = Application.get_env(:cleaner_crm, CleanerCrm.Billing.StripeGateway, [])

    on_exit(fn ->
      Application.put_env(:cleaner_crm, CleanerCrm.Billing.StripeGateway, original)
    end)

    Application.put_env(:cleaner_crm, CleanerCrm.Billing.StripeGateway, [])
    :ok
  end

  describe "create_payment_intent/1 with no STRIPE_SECRET_KEY configured" do
    test "returns an error tuple instead of raising" do
      assert {:error, %{"code" => "not_configured"}} =
               Live.create_payment_intent(%{amount_cents: 15_000, payment_method: "pm_card_visa"})
    end
  end

  describe "verify_webhook_event/1 with no STRIPE_WEBHOOK_SECRET configured" do
    test "returns an error tuple instead of raising, even with a signature header" do
      conn =
        Plug.Test.conn(:post, "/webhooks/stripe", %{"type" => "payment_intent.succeeded"})
        |> Plug.Conn.put_req_header("stripe-signature", "t=123,v1=deadbeef")
        |> Plug.Conn.assign(:raw_body, ~s({"type":"payment_intent.succeeded"}))

      assert {:error, :invalid_signature} = Live.verify_webhook_event(conn)
    end

    test "returns an error tuple when there's no signature header at all" do
      conn = Plug.Test.conn(:post, "/webhooks/stripe", %{"type" => "payment_intent.succeeded"})

      assert {:error, :invalid_signature} = Live.verify_webhook_event(conn)
    end
  end
end
