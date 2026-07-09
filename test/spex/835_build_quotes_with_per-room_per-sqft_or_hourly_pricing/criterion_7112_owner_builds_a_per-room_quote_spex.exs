defmodule CleanerCrmSpex.Story835.Criterion7112Spex do
  @moduledoc """
  Story 835 — Build quotes with per-room, per-sqft, or hourly pricing
  Criterion 7112 — Owner builds a per-room quote: selecting the per-room
  pricing model and entering room counts prices the quote per room, and
  no square-footage or hourly inputs are ever requested alongside it.
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

  spex "owner builds a per-room quote" do
    scenario "the quote is priced per room with no square-footage or hourly inputs requested" do
      given_ "the owner is creating a new quote for a lead", context do
        {:ok, quote_live, _html} = live(context.conn, ~p"/quotes/new")

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "the owner selects the per-room pricing model and adds 3 bedrooms and 2 bathrooms",
            context do
        html =
          context.quote_live
          |> form("[data-test='quote-form']",
            quote: %{pricing_model: "per_room", bedroom_count: 3, bathroom_count: 2}
          )
          |> render_change()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the quote is priced per room and no square-footage or hourly inputs are requested",
            context do
        assert has_element?(context.quote_live, "[data-test='room-bedroom-count-input']")
        assert has_element?(context.quote_live, "[data-test='room-bathroom-count-input']")
        refute has_element?(context.quote_live, "[data-test='square-feet-input']")
        refute has_element?(context.quote_live, "[data-test='hours-input']")

        {:ok, context}
      end
    end
  end
end
