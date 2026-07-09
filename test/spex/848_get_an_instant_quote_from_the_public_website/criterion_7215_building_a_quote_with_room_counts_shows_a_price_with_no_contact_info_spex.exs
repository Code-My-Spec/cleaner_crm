defmodule CleanerCrmSpex.Story848.Criterion7215Spex do
  @moduledoc """
  Story 848 — Get an instant quote from the public website
  Criterion 7215 — Building a quote with room counts shows a price
  with no contact info: a real price is shown from selecting a
  service type and room counts alone, before any name, email, or
  phone is entered.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the public quote form prices a per-room home before contact info is given" do
    scenario "building a quote with room counts shows a price with no contact info" do
      given_ "a business with a per-room rate card and a visitor on the public quote page",
             context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        Fixtures.rate_card_fixture(scope, %{
          per_room_bedroom_rate_cents: 5000,
          per_room_bathroom_rate_cents: 3000
        })

        {:ok, quote_live, _html} = live(context.conn, ~p"/book")

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "the visitor selects a service type, bedroom count, and bathroom count without entering a name, email, or phone",
            context do
        html =
          context.quote_live
          |> form("[data-test='quote-form']",
            quote: %{pricing_model: "per_room", bedroom_count: 3, bathroom_count: 2}
          )
          |> render_change()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "a real price computed from the rate card is displayed immediately", context do
        assert has_element?(context.quote_live, "[data-test='quote-total']", "$210.00")
        refute has_element?(context.quote_live, "[data-test='unsupported-quote-message']")

        {:ok, context}
      end
    end
  end
end
