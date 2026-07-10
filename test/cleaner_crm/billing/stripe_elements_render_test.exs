defmodule CleanerCrm.Billing.StripeElementsRenderTest do
  @moduledoc """
  Card-capture render coverage for `CleanerCrmWeb.BookingLive.Accept`
  (story 849) from the billing side: confirms the `:card_capture` step
  mounts the real Stripe Elements markup (`data-client-secret`,
  `data-publishable-key`) and omits the hidden test-card field once a
  publishable key is configured, and that the legacy hidden-field flow
  is what renders without one. No network involved — `Application.put_env`
  swaps only the app config the LiveView itself reads
  (`:stripe_publishable_key`); `client_secret` still comes from the fake
  `StripeGateway.Test` adapter (config/test.exs).

  Lives here rather than alongside `CleanerCrmWeb.BookingLive.AcceptTest`
  so this file's `async: false` (required by its global
  `Application.put_env(:cleaner_crm, :stripe_publishable_key, ...)`)
  can't collide with unrelated `async: true` work on that LiveView.
  """

  use CleanerCrmTest.ConnCase, async: false

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Booking
  alias CleanerCrm.Users.Scope

  defp scope_fixture do
    user = user_fixture()
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
          total_cents: 19_500,
          status: :accepted,
          client_name: "Dana Prescott",
          client_email: "dana-#{System.unique_integer([:positive])}@example.com",
          client_phone: "+15555550100"
        })
      )

    lead
  end

  defp advance_to_confirmation(conn, lead) do
    {:ok, accept_live, _html} = live(conn, ~p"/book/accept/#{lead.acceptance_token}")

    accept_live
    |> form("[data-test='slot-form']",
      booking: %{
        scheduled_date: Date.to_iso8601(Date.add(Date.utc_today(), 10)),
        start_time: "09:00"
      }
    )
    |> render_submit()

    accept_live
  end

  describe "with a publishable key configured (Stripe Elements)" do
    setup do
      Application.put_env(:cleaner_crm, :stripe_publishable_key, "pk_test_fake")
      on_exit(fn -> Application.delete_env(:cleaner_crm, :stripe_publishable_key) end)
      :ok
    end

    test "the card_capture step mounts the Payment Element with client-secret/publishable-key attrs and no hidden pm_card_visa field",
         %{conn: conn} do
      scope = scope_fixture()
      lead = lead_fixture(scope)
      accept_live = advance_to_confirmation(conn, lead)

      html = render(accept_live)
      refute html =~ ~s(name="booking[payment_method]")
      refute html =~ "pm_card_visa"

      accept_live
      |> form("[data-test='confirmation-form']", booking: %{policy_agreed: "true"})
      |> render_submit()

      assert has_element?(accept_live, "[data-test='stripe-payment-form']")
      assert has_element?(accept_live, "[data-test='stripe-payment-element']")

      html = render(accept_live)
      assert html =~ ~s(data-publishable-key="pk_test_fake")
      assert html =~ ~s(data-client-secret=")

      reloaded = Booking.get_lead_by_token(lead.acceptance_token)
      assert reloaded.status == :payment_pending
      assert reloaded.stripe_payment_intent_id != nil
    end
  end

  describe "without a publishable key configured (legacy hidden-field flow)" do
    test "the confirmation form carries the hidden pm_card_visa field and submitting it skips straight to payment_pending",
         %{conn: conn} do
      refute Application.get_env(:cleaner_crm, :stripe_publishable_key)

      scope = scope_fixture()
      lead = lead_fixture(scope)
      accept_live = advance_to_confirmation(conn, lead)

      html = render(accept_live)
      assert html =~ ~s(name="booking[payment_method]")
      assert html =~ "pm_card_visa"
      refute has_element?(accept_live, "[data-test='stripe-payment-form']")

      accept_live
      |> form("[data-test='confirmation-form']", booking: %{policy_agreed: "true"})
      |> render_submit()

      assert has_element?(accept_live, "[data-test='payment-pending']")
    end
  end
end
