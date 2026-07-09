defmodule CleanerCrmSpex.Story849.Criterion7236Spex do
  @moduledoc """
  Story 849 — Accept a quote and book online with card on file
  Criterion 7236 — Confirmed booking appears for client and business
  with portal access: confirming converts the accepted quote into a
  scheduled job visible to both sides, and the client receives a
  confirmation containing a magic-link to their portal.
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "confirming the booking makes the visit visible to both sides and grants portal access" do
    scenario "confirmed booking appears for client and business with portal access" do
      given_ "the booking has been confirmed with card on file", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        lead =
          Fixtures.lead_fixture(scope, %{
            total_cents: 19_500,
            client_name: "Dana Prescott",
            client_email: "dana@example.com"
          })

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

        payload = %{
          "type" => "payment_intent.succeeded",
          "data" => %{
            "object" => %{
              "id" => "pi_test_booking_confirmed",
              "metadata" => %{"lead_id" => to_string(lead.id)}
            }
          }
        }

        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> post("/webhooks/stripe", payload)
        |> Phoenix.ConnTest.json_response(200)

        owner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), user)

        {:ok, Map.merge(context, %{lead: lead, account: account, owner_conn: owner_conn})}
      end

      when_ "the confirmation completes", context do
        {:ok, context}
      end

      then_ "the visit appears as scheduled for both the business and the client, and the client receives a confirmation containing a magic-link to their portal",
            context do
        {:ok, accept_live, _html} =
          live(context.conn, ~p"/book/accept/#{context.lead.acceptance_token}")

        assert has_element?(accept_live, "[data-test='booking-confirmed']")

        {:ok, board_live, _html} = live(context.owner_conn, ~p"/schedule")
        assert render(board_live) =~ context.lead.client_name

        assert_email_sent(fn email ->
          email.to == [{"", context.lead.client_email}] and
            email.html_body =~ ~r{href="[^"]*portal[^"]*"}i
        end)

        {:ok, context}
      end
    end
  end
end
