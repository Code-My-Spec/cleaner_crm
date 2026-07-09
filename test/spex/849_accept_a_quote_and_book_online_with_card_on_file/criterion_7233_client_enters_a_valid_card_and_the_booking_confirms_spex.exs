defmodule CleanerCrmSpex.Story849.Criterion7233Spex do
  @moduledoc """
  Story 849 — Accept a quote and book online with card on file
  Criterion 7233 — Client enters a valid card and the booking
  confirms: once the payment gateway accepts the card, it is stored
  on file and the booking is confirmed.

  As with story 836's card charges, the gateway's acceptance is only
  final once the provider confirms it via `POST /webhooks/stripe`
  (see `CleanerCrm.Billing.receive_webhook/1`) — submitting the card
  moves the booking to a pending-payment state; this spec's subject
  is the transition that follows the provider's confirmation.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the payment gateway accepting the card confirms the booking" do
    scenario "client enters a valid card and the booking confirms" do
      given_ "the client has agreed to the cancellation policy", context do
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

        {:ok, Map.merge(context, %{lead: lead, accept_live: accept_live})}
      end

      when_ "the client enters a valid card and the payment gateway accepts it", context do
        context.accept_live
        |> form("[data-test='confirmation-form']",
          booking: %{policy_agreed: "true", payment_method: "pm_card_visa"}
        )
        |> render_submit()

        assert has_element?(context.accept_live, "[data-test='payment-pending']")

        payload = %{
          "type" => "payment_intent.succeeded",
          "data" => %{
            "object" => %{
              "id" => "pi_test_booking_succeeded",
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

      then_ "the card is stored on file and the booking is confirmed", context do
        {:ok, accept_live, _html} =
          live(context.conn, ~p"/book/accept/#{context.lead.acceptance_token}")

        assert has_element?(accept_live, "[data-test='booking-confirmed']")

        {:ok, context}
      end
    end
  end
end
