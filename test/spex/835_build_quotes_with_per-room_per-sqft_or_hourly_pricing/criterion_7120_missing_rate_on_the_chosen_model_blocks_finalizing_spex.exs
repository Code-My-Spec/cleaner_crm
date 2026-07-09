defmodule CleanerCrmSpex.Story835.Criterion7120Spex do
  @moduledoc """
  Story 835 — Build quotes with per-room, per-sqft, or hourly pricing
  Criterion 7120 — Missing rate on the chosen model blocks finalizing:
  a quote cannot be finalized until every line item in the chosen model
  has a rate and the total is greater than zero.
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

  spex "missing rate on the chosen model blocks finalizing" do
    scenario "finalizing is blocked and the owner is prompted to set the missing rate" do
      given_ "the owner's rate card has no rate configured for the hourly model", context do
        {:ok, quote_live, _html} = live(context.conn, ~p"/app/quotes/new")

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "the owner builds an hourly quote and tries to finalize it", context do
        context.quote_live
        |> form("[data-test='quote-form']", quote: %{pricing_model: "hourly", hours: 3})
        |> render_change()

        html =
          context.quote_live
          |> element("[data-test='send-quote-button']")
          |> render_click()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "finalizing is blocked and the owner is prompted to set the missing rate before sending, preventing a zero-dollar quote",
            context do
        assert has_element?(context.quote_live, "[data-test='hours-input'][value='3']")
        assert has_element?(context.quote_live, "[data-test='missing-rate-warning']")
        assert has_element?(context.quote_live, "[data-test='quote-total']", "$0.00")

        {:ok, context}
      end
    end
  end
end
