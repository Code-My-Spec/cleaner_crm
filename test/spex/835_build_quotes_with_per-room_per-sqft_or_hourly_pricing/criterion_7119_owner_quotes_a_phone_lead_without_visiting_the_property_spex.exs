defmodule CleanerCrmSpex.Story835.Criterion7119Spex do
  @moduledoc """
  Story 835 — Build quotes with per-room, per-sqft, or hourly pricing
  Criterion 7119 — Owner quotes a phone lead without visiting the
  property: a quote can be built and sent entirely from client-supplied
  details, with no in-person walkthrough required first.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  setup context do
    user = Fixtures.user_fixture()
    scope = Fixtures.user_scope_fixture(user)
    account = Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})
    conn = CleanerCrmTest.ConnCase.log_in_user(context.conn, user)

    {:ok, conn: conn, user: user, account: account}
  end

  spex "owner quotes a phone lead without visiting the property" do
    scenario "a complete priced quote is sent without scheduling a site visit" do
      given_ "a lead has given the owner their room count and square footage over the phone",
             context do
        {:ok, quote_live, _html} = live(context.conn, ~p"/quotes/new")

        quote_live
        |> form("[data-test='rate-card-form']",
          rate_card: %{per_room_bedroom_rate_cents: 5000, per_room_bathroom_rate_cents: 3000}
        )
        |> render_submit()

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "the owner builds a quote entering those details from their device", context do
        context.quote_live
        |> form("[data-test='quote-form']",
          quote: %{
            client_name: "Dana Prescott",
            client_phone: "555-0142",
            pricing_model: "per_room",
            bedroom_count: 3,
            bathroom_count: 1
          }
        )
        |> render_change()

        context.quote_live
        |> element("[data-test='send-quote-button']")
        |> render_click()

        {:ok, context}
      end

      then_ "the owner can produce and send a complete priced quote without scheduling a site visit",
            context do
        path = assert_patch(context.quote_live)
        {:ok, sent_live, html} = live(context.conn, path)

        assert html =~ "$180.00"
        assert has_element?(sent_live, "[data-test='quote-status']", "Sent")
        refute html =~ "Schedule a site visit"

        {:ok, context}
      end
    end
  end
end
