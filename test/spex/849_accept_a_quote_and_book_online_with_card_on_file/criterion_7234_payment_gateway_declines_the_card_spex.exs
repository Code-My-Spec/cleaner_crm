defmodule CleanerCrmSpex.Story849.Criterion7234Spex do
  @moduledoc """
  Story 849 — Accept a quote and book online with card on file
  Criterion 7234 — Payment gateway declines the card: the booking is
  not confirmed and the client is prompted to retry with a different
  card.

  Mirrors story 836's decline handling: the provider's decline
  arrives via `POST /webhooks/stripe` (`payment_intent.payment_failed`),
  never as a synchronous response to submitting the card.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the payment gateway declining the card leaves the booking unconfirmed" do
    scenario "payment gateway declines the card" do
      given_ "the client has agreed to the cancellation policy and submitted a card", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        lead = Fixtures.lead_fixture(scope, %{total_cents: 19_500})

        {:ok, accept_live, _html} = live(context.conn, ~p"/book/accept/#{lead.acceptance_token}")

        accept_live
        |> form("[data-test='slot-form']",
          booking: %{scheduled_date: Date.add(Date.utc_today(), 10), start_time: "09:00"}
        )
        |> render_submit()

        accept_live
        |> form("[data-test='confirmation-form']",
          booking: %{policy_agreed: "true", payment_method: "pm_card_visa"}
        )
        |> render_submit()

        assert has_element?(accept_live, "[data-test='payment-pending']")

        {:ok, Map.merge(context, %{lead: lead, accept_live: accept_live})}
      end

      when_ "the payment gateway declines the card", context do
        payload = %{
          "type" => "payment_intent.payment_failed",
          "data" => %{
            "object" => %{
              "id" => "pi_test_booking_declined",
              "metadata" => %{"lead_id" => to_string(context.lead.id)}
            }
          }
        }

        response =
          Phoenix.ConnTest.build_conn()
          |> Plug.Conn.put_req_header("content-type", "application/json")
          |> post("/webhooks/stripe", payload)
          |> Phoenix.ConnTest.json_response(200)

        {:ok, Map.put(context, :webhook_response, response)}
      end

      then_ "the booking is not confirmed and the client is prompted to retry with a different card",
            context do
        {:ok, accept_live, _html} =
          live(context.conn, ~p"/book/accept/#{context.lead.acceptance_token}")

        assert has_element?(accept_live, "[data-test='payment-declined-message']")
        refute has_element?(accept_live, "[data-test='booking-confirmed']")

        {:ok, context}
      end
    end
  end
end
