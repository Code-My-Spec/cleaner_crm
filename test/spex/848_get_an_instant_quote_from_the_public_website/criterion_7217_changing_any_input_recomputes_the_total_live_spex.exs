defmodule CleanerCrmSpex.Story848.Criterion7217Spex do
  @moduledoc """
  Story 848 — Get an instant quote from the public website
  Criterion 7217 — Changing any input recomputes the total live: the
  displayed price updates immediately as any input changes, with no
  page reload.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the displayed total recomputes live as inputs change" do
    scenario "changing any input recomputes the total live" do
      given_ "a quote is currently displayed for a 2-bedroom home", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        Fixtures.rate_card_fixture(scope, %{
          per_room_bedroom_rate_cents: 5000,
          per_room_bathroom_rate_cents: 3000
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

      when_ "the visitor changes the bedroom count to 3", context do
        html =
          context.quote_live
          |> form("[data-test='quote-form']", quote: %{bedroom_count: 3})
          |> render_change()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the displayed price updates immediately to reflect the new bedroom count without a page reload",
            context do
        assert has_element?(context.quote_live, "[data-test='quote-total']", "$150.00")
        refute has_element?(context.quote_live, "[data-test='quote-total']", "$100.00")

        {:ok, context}
      end
    end
  end
end
