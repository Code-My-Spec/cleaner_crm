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
  alias CleanerCrm.Billing.StripeGateway.Test, as: TestGateway

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

    # Regression: the booking-acceptance page's Stripe Elements flow
    # (`CleanerCrm.Booking.confirm_booking/3`) calls this with
    # `confirm: false` and no `payment_method` at all — the relaxed
    # function head (`amount_cents` only) must still reach the same
    # graceful `fetch_secret_key/0` guard rather than raising a
    # FunctionClauseError.
    test "returns an error tuple for the unconfirmed-intent shape too" do
      assert {:error, %{"code" => "not_configured"}} =
               Live.create_payment_intent(%{amount_cents: 15_000, confirm: false})
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

  describe "StripeGateway.Test.create_payment_intent/1" do
    test "fabricates an id, a succeeded status, and a client_secret shaped like Stripe's own" do
      assert {:ok, %{id: id, status: "succeeded", client_secret: client_secret}} =
               TestGateway.create_payment_intent(%{amount_cents: 15_000, confirm: false})

      assert String.starts_with?(id, "pi_test_")
      assert client_secret == "#{id}_secret_test"
    end

    # The booking-acceptance page's confirmed (dev/test hidden-card)
    # and unconfirmed (Elements) paths both call through this same
    # adapter — it must satisfy either params shape identically, since
    # it ignores params entirely (see its own moduledoc).
    test "returns the same shape regardless of params" do
      assert {:ok, %{id: _, status: "succeeded", client_secret: _}} =
               TestGateway.create_payment_intent(%{
                 amount_cents: 15_000,
                 payment_method: "pm_card_visa"
               })
    end

    test "each call fabricates a distinct id" do
      {:ok, %{id: first_id}} = TestGateway.create_payment_intent(%{amount_cents: 15_000})
      {:ok, %{id: second_id}} = TestGateway.create_payment_intent(%{amount_cents: 15_000})

      assert first_id != second_id
    end
  end
end
