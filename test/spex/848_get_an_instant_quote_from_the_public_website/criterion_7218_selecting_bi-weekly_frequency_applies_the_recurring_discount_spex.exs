defmodule CleanerCrmSpex.Story848.Criterion7218Spex do
  @moduledoc """
  Story 848 — Get an instant quote from the public website
  Criterion 7218 — Selecting bi-weekly frequency applies the
  recurring discount configured on the rate card to the one-time
  subtotal.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "bi-weekly frequency applies the rate card's recurring discount" do
    scenario "selecting bi-weekly frequency applies the recurring discount" do
      given_ "a one-time quote subtotal has been computed", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        Fixtures.rate_card_fixture(scope, %{
          per_room_bedroom_rate_cents: 5000,
          per_room_bathroom_rate_cents: 3000,
          biweekly_discount_percent: 10
        })

        {:ok, quote_live, _html} = live(context.conn, ~p"/book")

        quote_live
        |> form("[data-test='quote-form']",
          quote: %{
            pricing_model: "per_room",
            bedroom_count: 2,
            bathroom_count: 0,
            frequency: "one_time"
          }
        )
        |> render_change()

        assert has_element?(quote_live, "[data-test='quote-total']", "$100.00")

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "the visitor changes the frequency to bi-weekly", context do
        html =
          context.quote_live
          |> form("[data-test='quote-form']", quote: %{frequency: "biweekly"})
          |> render_change()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the displayed total is reduced by the rate card's configured bi-weekly discount",
            context do
        assert has_element?(context.quote_live, "[data-test='quote-total']", "$90.00")

        {:ok, context}
      end
    end
  end
end
