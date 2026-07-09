defmodule CleanerCrmSpex.Story848.Criterion7216Spex do
  @moduledoc """
  Story 848 — Get an instant quote from the public website
  Criterion 7216 — Building a quote by square footage instead of room
  counts: the same public form prices a home from square footage
  against the account's per-square-foot rate.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the public quote form prices a home by square footage" do
    scenario "building a quote by square footage instead of room counts" do
      given_ "a business with a per-square-foot rate card", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        Fixtures.rate_card_fixture(scope, %{per_sqft_rate_cents: 10})

        {:ok, quote_live, _html} = live(context.conn, ~p"/book")

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "the visitor enters the home's square footage and a service type", context do
        html =
          context.quote_live
          |> form("[data-test='quote-form']",
            quote: %{pricing_model: "per_sqft", square_feet: 2000}
          )
          |> render_change()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the displayed price is computed using the per-square-foot rate", context do
        assert has_element?(context.quote_live, "[data-test='quote-total']", "$200.00")

        {:ok, context}
      end
    end
  end
end
