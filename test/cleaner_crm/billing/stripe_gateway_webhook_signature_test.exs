defmodule CleanerCrm.Billing.StripeGatewayWebhookSignatureTest do
  @moduledoc """
  Pure-crypto coverage for `StripeGateway.Live.verify_webhook_event/1` —
  no cassette needed, signature verification never leaves the process
  (see `.code_my_spec/architecture/decisions/req_cassette.md` for why
  the HTTP calls elsewhere in this module ARE cassette-backed).
  Complements `CleanerCrm.Billing.StripeGatewayTest`, which only covers
  the missing-webhook-secret case.
  """

  use ExUnit.Case, async: false

  alias CleanerCrm.Billing.StripeGateway.Live

  @webhook_secret "whsec_test_signature_fixture"

  setup do
    original = Application.get_env(:cleaner_crm, CleanerCrm.Billing.StripeGateway, [])

    Application.put_env(:cleaner_crm, CleanerCrm.Billing.StripeGateway,
      webhook_secret: @webhook_secret
    )

    on_exit(fn ->
      Application.put_env(:cleaner_crm, CleanerCrm.Billing.StripeGateway, original)
    end)

    :ok
  end

  defp signed_conn(payload, opts \\ []) do
    secret = Keyword.get(opts, :secret, @webhook_secret)
    timestamp = Keyword.get(opts, :timestamp, System.system_time(:second))
    signed_payload = "#{timestamp}.#{payload}"

    signature =
      :hmac
      |> :crypto.mac(:sha256, secret, signed_payload)
      |> Base.encode16(case: :lower)

    Plug.Test.conn(:post, "/webhooks/stripe", Jason.decode!(payload))
    |> Plug.Conn.put_req_header("stripe-signature", "t=#{timestamp},v1=#{signature}")
    |> Plug.Conn.assign(:raw_body, payload)
  end

  test "accepts a payload with a validly signed header" do
    payload = ~s({"type":"payment_intent.succeeded","id":"evt_1"})

    assert {:ok, params} = payload |> signed_conn() |> Live.verify_webhook_event()
    assert params["type"] == "payment_intent.succeeded"
  end

  test "rejects a payload whose raw body was tampered with after signing" do
    original_payload = ~s({"type":"payment_intent.succeeded","id":"evt_1"})
    tampered_payload = ~s({"type":"payment_intent.succeeded","id":"evt_2"})

    conn =
      original_payload
      |> signed_conn()
      |> Plug.Conn.assign(:raw_body, tampered_payload)

    assert {:error, :invalid_signature} = Live.verify_webhook_event(conn)
  end

  test "rejects a signature computed with the wrong secret" do
    payload = ~s({"type":"payment_intent.succeeded","id":"evt_1"})
    conn = signed_conn(payload, secret: "whsec_wrong_secret")

    assert {:error, :invalid_signature} = Live.verify_webhook_event(conn)
  end

  # Replay protection: a validly-signed payload outside the 5-minute
  # tolerance window is rejected (Stripe's recommended check).
  test "rejects a stale but correctly-signed timestamp" do
    payload = ~s({"type":"payment_intent.succeeded","id":"evt_1"})
    one_year_ago = System.system_time(:second) - 60 * 60 * 24 * 365
    conn = signed_conn(payload, timestamp: one_year_ago)

    assert {:error, :invalid_signature} = Live.verify_webhook_event(conn)
  end

  test "accepts a fresh timestamp inside the tolerance window" do
    payload = ~s({"type":"payment_intent.succeeded","id":"evt_2"})
    conn = signed_conn(payload, timestamp: System.system_time(:second) - 60)

    assert {:ok, _params} = Live.verify_webhook_event(conn)
  end
end
