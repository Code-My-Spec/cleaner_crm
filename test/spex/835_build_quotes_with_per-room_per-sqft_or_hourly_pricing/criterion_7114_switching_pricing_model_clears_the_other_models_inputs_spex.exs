defmodule CleanerCrmSpex.Story835.Criterion7114Spex do
  @moduledoc """
  Story 835 — Build quotes with per-room, per-sqft, or hourly pricing
  Criterion 7114 — Switching pricing model clears the other model's
  inputs: a quote is priced by exactly one model at a time, so changing
  the model wipes out line items that belonged to the previous model.
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

  spex "switching pricing model clears the other model's inputs" do
    scenario "per-room line items are cleared and the quote is priced only on hours" do
      given_ "the owner has started a per-room quote with rooms entered", context do
        {:ok, quote_live, _html} = live(context.conn, ~p"/app/quotes/new")

        quote_live
        |> form("[data-test='quote-form']",
          quote: %{pricing_model: "per_room", bedroom_count: 3, bathroom_count: 1}
        )
        |> render_change()

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "the owner switches the pricing model to hourly", context do
        html =
          context.quote_live
          |> form("[data-test='quote-form']", quote: %{pricing_model: "hourly"})
          |> render_change()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the per-room line items are cleared and the quote is priced only on hours, never a mix of both models",
            context do
        refute has_element?(context.quote_live, "[data-test='room-bedroom-count-input']")
        refute has_element?(context.quote_live, "[data-test='room-bathroom-count-input']")
        assert has_element?(context.quote_live, "[data-test='hours-input']")
        assert has_element?(context.quote_live, "[data-test='quote-total']", "$0.00")

        {:ok, context}
      end
    end
  end
end
