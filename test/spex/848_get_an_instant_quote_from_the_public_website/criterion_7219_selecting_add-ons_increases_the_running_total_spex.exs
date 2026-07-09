defmodule CleanerCrmSpex.Story848.Criterion7219Spex do
  @moduledoc """
  Story 848 — Get an instant quote from the public website
  Criterion 7219 — Selecting add-ons increases the running total by
  the sum of each selected add-on's configured amount.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "each selected add-on adds its configured amount to the running total" do
    scenario "selecting add-ons increases the running total" do
      given_ "a base quote is displayed with no add-ons selected", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        Fixtures.rate_card_fixture(scope, %{
          per_room_bedroom_rate_cents: 5000,
          per_room_bathroom_rate_cents: 3000,
          add_on_rates_cents: %{"inside_fridge" => 1500, "interior_windows" => 2000}
        })

        {:ok, quote_live, _html} = live(context.conn, ~p"/book")

        quote_live
        |> form("[data-test='quote-form']",
          quote: %{pricing_model: "per_room", bedroom_count: 2, bathroom_count: 0}
        )
        |> render_change()

        assert has_element?(quote_live, "[data-test='quote-total']", "$100.00")

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "the visitor selects \"inside fridge\" and \"interior windows\" add-ons", context do
        html =
          context.quote_live
          |> form("[data-test='quote-form']",
            quote: %{add_ons: ["inside_fridge", "interior_windows"]}
          )
          |> render_change()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the running total increases by the sum of both add-ons' configured amounts",
            context do
        assert has_element?(context.quote_live, "[data-test='quote-total']", "$135.00")

        {:ok, context}
      end
    end
  end
end
