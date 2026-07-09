defmodule CleanerCrmSpex.Story835.Criterion7122Spex do
  @moduledoc """
  Story 835 — Build quotes with per-room, per-sqft, or hourly pricing
  Criterion 7122 — Rate-card change does not alter an already-sent
  quote: a sent quote captures the rates and amounts at the moment it
  was sent, so later rate-card edits never change it.
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

  spex "rate-card change does not alter an already-sent quote" do
    scenario "the previously sent quote still shows its original total after rates rise" do
      given_ "the owner sent a quote totaling $200 using the current rate card", context do
        {:ok, quote_live, _html} = live(context.conn, ~p"/quotes/new")

        quote_live
        |> form("[data-test='rate-card-form']", rate_card: %{per_sqft_rate_cents: 10})
        |> render_submit()

        quote_live
        |> form("[data-test='quote-form']",
          quote: %{client_name: "Morgan Ruiz", pricing_model: "per_sqft", square_feet: 2000}
        )
        |> render_change()

        quote_live
        |> element("[data-test='send-quote-button']")
        |> render_click()

        sent_quote_path = assert_patch(quote_live)

        {:ok, Map.merge(context, %{quote_live: quote_live, sent_quote_path: sent_quote_path})}
      end

      when_ "the owner later raises the rate card rates", context do
        {:ok, new_quote_live, _html} = live(context.conn, ~p"/quotes/new")

        new_quote_live
        |> form("[data-test='rate-card-form']", rate_card: %{per_sqft_rate_cents: 20})
        |> render_submit()

        {:ok, context}
      end

      then_ "the previously sent quote still shows $200 and its line items are unchanged",
            context do
        {:ok, sent_live, html} = live(context.conn, context.sent_quote_path)

        assert html =~ "$200.00"
        assert has_element?(sent_live, "[data-test='quote-total']", "$200.00")
        refute has_element?(sent_live, "[data-test='quote-total']", "$400.00")

        {:ok, context}
      end
    end
  end
end
