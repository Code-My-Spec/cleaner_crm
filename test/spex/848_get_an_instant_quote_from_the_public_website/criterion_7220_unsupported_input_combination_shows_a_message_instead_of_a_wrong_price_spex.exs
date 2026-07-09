defmodule CleanerCrmSpex.Story848.Criterion7220Spex do
  @moduledoc """
  Story 848 — Get an instant quote from the public website
  Criterion 7220 — Unsupported input combination shows a message
  instead of a wrong price: when the rate card can't price a selected
  service type and size combination, the form withholds a price
  rather than showing $0 or a guess.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "an unpriceable combination shows a clear message instead of a wrong price" do
    scenario "unsupported input combination shows a message instead of a wrong price" do
      given_ "a business's rate card has no configured price for a selected service type and size combination",
             context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        Fixtures.rate_card_fixture(scope, %{
          per_room_bedroom_rate_cents: 5000,
          per_room_bathroom_rate_cents: 3000,
          per_sqft_rate_cents: nil
        })

        {:ok, quote_live, _html} = live(context.conn, ~p"/book")

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "the visitor selects that unsupported combination", context do
        html =
          context.quote_live
          |> form("[data-test='quote-form']",
            quote: %{pricing_model: "per_sqft", square_feet: 2000}
          )
          |> render_change()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the form shows a clear \"can't price this yet, request a custom quote\" message instead of displaying $0 or a guessed price",
            context do
        assert has_element?(context.quote_live, "[data-test='unsupported-quote-message']")
        assert render(context.quote_live) =~ "can't price this yet"
        assert render(context.quote_live) =~ "request a custom quote"
        refute has_element?(context.quote_live, "[data-test='quote-total']", "$0.00")

        {:ok, context}
      end
    end
  end
end
