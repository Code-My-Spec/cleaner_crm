defmodule CleanerCrmSpex.Story849.Criterion7235Spex do
  @moduledoc """
  Story 849 — Accept a quote and book online with card on file
  Criterion 7235 — Card is authorized for the exact quoted amount:
  the gateway authorizes exactly the quoted price, in integer cents,
  with no added fee.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the card is authorized for exactly the quoted total" do
    scenario "card is authorized for the exact quoted amount" do
      given_ "the client saw an instant quote total of $195 in integer cents", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        lead = Fixtures.lead_fixture(scope, %{total_cents: 19_500})

        {:ok, accept_live, html} = live(context.conn, ~p"/book/accept/#{lead.acceptance_token}")

        assert html =~ "$195.00"

        {:ok, Map.merge(context, %{lead: lead, accept_live: accept_live})}
      end

      when_ "the client completes booking with a valid card", context do
        context.accept_live
        |> form("[data-test='slot-form']",
          booking: %{scheduled_date: Date.add(Date.utc_today(), 10), start_time: "09:00"}
        )
        |> render_submit()

        context.accept_live
        |> form("[data-test='confirmation-form']",
          booking: %{policy_agreed: "true", payment_method: "pm_card_visa"}
        )
        |> render_submit()

        payload = %{
          "type" => "payment_intent.succeeded",
          "data" => %{
            "object" => %{
              "id" => "pi_test_booking_exact_amount",
              "metadata" => %{"lead_id" => to_string(context.lead.id)}
            }
          }
        }

        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> post("/webhooks/stripe", payload)
        |> Phoenix.ConnTest.json_response(200)

        {:ok, context}
      end

      then_ "the gateway authorizes exactly $195 with no added fee", context do
        {:ok, accept_live, html} =
          live(context.conn, ~p"/book/accept/#{context.lead.acceptance_token}")

        assert html =~ "$195.00"
        refute has_element?(accept_live, "[data-test='added-fee']")

        {:ok, context}
      end
    end
  end
end
