defmodule CleanerCrm.Billing.StripeGatewayLiveCassetteTest do
  @moduledoc """
  Exercises `CleanerCrm.Billing.StripeGateway.Live` against recorded
  Stripe TEST-mode responses (see
  `.code_my_spec/architecture/decisions/req_cassette.md`). Before this
  file, only the fake `StripeGateway.Test` adapter had any coverage —
  `Live`'s actual request shape (`automatic_payment_methods`, confirmed
  vs. unconfirmed intents, decline/parameter-error handling) shipped to
  UAT with zero verification and a real bug (missing
  `automatic_payment_methods`) went undetected.

  Every cassette here was recorded once against the real Stripe API in
  test mode; every other run replays it offline (`cassette_mode/0` only
  switches to `:record` when `STRIPE_SECRET_KEY` is set), so CI never
  needs a key and never reaches the network. `async: false` because
  `req_http_options`/the adapter's credentials are process-global
  `Application` config for the duration of each cassette.
  """

  use ExUnit.Case, async: false

  import ReqCassette

  alias CleanerCrm.Billing.StripeGateway.Live

  @cassette_dir "test/cassettes/stripe"

  setup do
    original = Application.get_env(:cleaner_crm, CleanerCrm.Billing.StripeGateway, [])

    Application.put_env(:cleaner_crm, CleanerCrm.Billing.StripeGateway,
      secret_key: System.get_env("STRIPE_SECRET_KEY") || "sk_test_offline_replay_only",
      webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET") || "whsec_offline_replay_only"
    )

    on_exit(fn ->
      Application.put_env(:cleaner_crm, CleanerCrm.Billing.StripeGateway, original)
      Application.delete_env(:cleaner_crm, :req_http_options)
    end)

    :ok
  end

  # `:record` only for the one-time run against real Stripe test mode;
  # every other run is `:replay`, which raises instead of silently
  # reaching the network if a cassette/interaction is missing. Read at
  # runtime (not a module attribute) so an offline CI run is never
  # accidentally stuck in `:record` from how the module last compiled.
  defp cassette_mode do
    if System.get_env("STRIPE_SECRET_KEY"), do: :record, else: :replay
  end

  defp with_stripe_cassette(name, fun) do
    opts = [
      cassette_name: name,
      cassette_dir: @cassette_dir,
      filter_request_headers: ["authorization"],
      mode: cassette_mode(),
      match_requests_on: [:method, :uri, :body]
    ]

    with_cassette(name, opts, fn plug ->
      Application.put_env(:cleaner_crm, :req_http_options, plug: plug)
      result = fun.()
      Application.delete_env(:cleaner_crm, :req_http_options)
      result
    end)
  end

  defp recorded_request_body(cassette_name) do
    @cassette_dir
    |> Path.join("#{cassette_name}.json")
    |> File.read!()
    |> Jason.decode!()
    |> Map.fetch!("interactions")
    |> List.last()
    |> get_in(["request", "body"])
  end

  describe "create_payment_intent/1 — confirmed happy path" do
    test "pm_card_visa confirms synchronously and succeeds" do
      result =
        with_stripe_cassette("create_payment_intent_confirmed_success", fn ->
          Live.create_payment_intent(%{
            amount_cents: 1500,
            payment_method: "pm_card_visa",
            off_session: false
          })
        end)

      assert {:ok, %{id: id, status: "succeeded", client_secret: _}} = result
      assert String.starts_with?(id, "pi_")

      body = recorded_request_body("create_payment_intent_confirmed_success")
      assert body =~ "amount=1500"
      assert body =~ "currency=usd"
      assert body =~ "automatic_payment_methods%5Benabled%5D=true"
      assert body =~ "automatic_payment_methods%5Ballow_redirects%5D=never"
      assert body =~ "payment_method=pm_card_visa"
      assert body =~ "confirm=true"
    end
  end

  describe "create_payment_intent/1 — unconfirmed (Stripe Elements flow)" do
    test "confirm: false leaves the intent open and returns a client_secret" do
      result =
        with_stripe_cassette("create_payment_intent_unconfirmed", fn ->
          Live.create_payment_intent(%{amount_cents: 1500, confirm: false})
        end)

      assert {:ok, %{id: id, status: status, client_secret: client_secret}} = result
      assert String.starts_with?(id, "pi_")
      assert status == "requires_payment_method"
      assert is_binary(client_secret)

      body = recorded_request_body("create_payment_intent_unconfirmed")
      assert body =~ "automatic_payment_methods%5Benabled%5D=true"
      refute body =~ "confirm=true"
      refute body =~ "payment_method="
    end
  end

  describe "create_payment_intent/1 — declined card" do
    test "pm_card_visa_chargeDeclined comes back as an error tuple with decline info" do
      result =
        with_stripe_cassette("create_payment_intent_declined", fn ->
          Live.create_payment_intent(%{
            amount_cents: 1500,
            payment_method: "pm_card_visa_chargeDeclined",
            off_session: false
          })
        end)

      assert {:error, %{"code" => "card_declined", "decline_code" => _}} = result
    end
  end

  describe "create_payment_intent/1 — parameter error" do
    test "an amount below Stripe's minimum comes back as an error tuple, not a crash" do
      result =
        with_stripe_cassette("create_payment_intent_param_error", fn ->
          Live.create_payment_intent(%{amount_cents: 0, confirm: false})
        end)

      assert {:error, %{"param" => "amount"}} = result
    end
  end
end
