defmodule CleanerCrmSpex.Story835.Criterion7116Spex do
  @moduledoc """
  Story 835 — Build quotes with per-room, per-sqft, or hourly pricing
  Criterion 7116 — Per-square-foot total computes from the rate card:
  the quote total is derived by applying the owner's saved per-sqft
  rate to the entered square footage.
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

  spex "per-square-foot total computes from the rate card" do
    scenario "the quote total is calculated from the saved per-sqft rate" do
      given_ "the owner's rate card has a per-square-foot rate of $0.10", context do
        {:ok, quote_live, _html} = live(context.conn, ~p"/app/quotes/new")

        quote_live
        |> form("[data-test='rate-card-form']", rate_card: %{per_sqft_rate_cents: 10})
        |> render_submit()

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "the owner selects per-square-foot pricing and enters 2,000 square feet", context do
        html =
          context.quote_live
          |> form("[data-test='quote-form']",
            quote: %{pricing_model: "per_sqft", square_feet: 2000}
          )
          |> render_change()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the quote total is calculated as $200", context do
        assert has_element?(context.quote_live, "[data-test='quote-total']", "$200.00")
        refute has_element?(context.quote_live, "[data-test='quote-total']", "$0.00")

        {:ok, context}
      end
    end
  end
end
