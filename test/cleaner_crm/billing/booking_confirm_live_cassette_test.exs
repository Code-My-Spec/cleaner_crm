defmodule CleanerCrm.Billing.BookingConfirmLiveCassetteTest do
  @moduledoc """
  Story 849's booking-acceptance flow (`CleanerCrm.Booking.confirm_booking/3`)
  is covered everywhere else against the fake `StripeGateway.Test` adapter
  (see `CleanerCrm.BookingTest`), which always succeeds regardless of
  params. This drives the same Stripe-Elements (unconfirmed-intent) path
  through the real `Live` adapter against a recorded Stripe TEST-mode
  response, so a regression in how `Booking` talks to Stripe can't hide
  behind the fake adapter.

  Matches only on `[:method, :uri]` (not `:body`) — `submit_unconfirmed_payment/1`
  sends `metadata[lead_id]`, and `Lead.id` is a fresh UUID every run, so
  matching on body would never replay. Body-level param assertions
  belong to `CleanerCrm.Billing.StripeGatewayLiveCassetteTest`, which
  calls `Live.create_payment_intent/1` directly with fixed params.
  """

  use CleanerCrmTest.DataCase, async: false

  import ReqCassette

  alias CleanerCrm.Accounts
  alias CleanerCrm.Billing.StripeGateway
  alias CleanerCrm.Booking
  alias CleanerCrm.Users.Scope

  @cassette_dir "test/cassettes/stripe"

  setup do
    original_gateway = Application.get_env(:cleaner_crm, StripeGateway, [])

    Application.put_env(:cleaner_crm, StripeGateway,
      adapter: StripeGateway.Live,
      secret_key: System.get_env("STRIPE_SECRET_KEY") || "sk_test_offline_replay_only",
      webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET") || "whsec_offline_replay_only"
    )

    on_exit(fn ->
      Application.put_env(:cleaner_crm, StripeGateway, original_gateway)
      Application.delete_env(:cleaner_crm, :req_http_options)
    end)

    :ok
  end

  defp cassette_mode do
    if System.get_env("STRIPE_SECRET_KEY"), do: :record, else: :replay
  end

  defp scope_fixture do
    user = CleanerCrm.UsersFixtures.user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

    %{scope | active_account: account, active_account_id: account.id}
  end

  defp lead_fixture(scope, attrs \\ %{}) do
    {:ok, lead} =
      Booking.create_lead(
        scope,
        Enum.into(attrs, %{
          pricing_model: :per_room,
          bedroom_count: 3,
          bathroom_count: 2,
          frequency: :one_time,
          total_cents: 1500,
          status: :accepted,
          client_name: "Dana Prescott",
          client_email: "dana-#{System.unique_integer([:positive])}@example.com",
          client_phone: "+15555550100"
        })
      )

    lead
  end

  test "confirm_booking/3 against the real Live adapter creates an unconfirmed intent and returns a client_secret" do
    scope = scope_fixture()
    lead = lead_fixture(scope)

    {:ok, slotted} =
      Booking.select_slot(lead, %{
        "scheduled_date" => Date.to_iso8601(Date.add(Date.utc_today(), 10)),
        "start_time" => "09:00"
      })

    opts = [
      cassette_name: "booking_confirm_unconfirmed_intent",
      cassette_dir: @cassette_dir,
      filter_request_headers: ["authorization"],
      mode: cassette_mode(),
      match_requests_on: [:method, :uri]
    ]

    result =
      with_cassette("booking_confirm_unconfirmed_intent", opts, fn plug ->
        Application.put_env(:cleaner_crm, :req_http_options, plug: plug)
        result = Booking.confirm_booking(slotted, %{"policy_agreed" => "true"})
        Application.delete_env(:cleaner_crm, :req_http_options)
        result
      end)

    assert {:ok, %{lead: updated, client_secret: client_secret}} = result
    assert updated.status == :payment_pending
    assert updated.stripe_payment_intent_id != nil
    assert is_binary(client_secret)
  end
end
