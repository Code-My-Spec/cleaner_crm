defmodule CleanerCrmSpex.Story848.Criterion7221Spex do
  @moduledoc """
  Story 848 — Get an instant quote from the public website
  Criterion 7221 — Instant quote price matches the later acceptance
  total: the number shown on the instant-quote calculator is exactly
  the number carried through to the accept-and-book step, with no
  added fees.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the instant quote total carries through unchanged to acceptance" do
    scenario "instant quote price matches the later acceptance total" do
      given_ "a visitor sees an instant quote total of $195 in integer cents", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        Fixtures.rate_card_fixture(scope, %{
          per_room_bedroom_rate_cents: 6000,
          per_room_bathroom_rate_cents: 3750
        })

        {:ok, quote_live, _html} = live(context.conn, ~p"/book")

        quote_live
        |> form("[data-test='quote-form']",
          quote: %{pricing_model: "per_room", bedroom_count: 2, bathroom_count: 2}
        )
        |> render_change()

        assert has_element?(quote_live, "[data-test='quote-total']", "$195.00")

        {:ok, Map.put(context, :quote_live, quote_live)}
      end

      when_ "they proceed to the accept-and-book step without changing any selections", context do
        context.quote_live
        |> form("[data-test='lead-contact-form']",
          lead: %{name: "Dana Prescott", email: "dana@example.com", phone: "555-0142"}
        )
        |> render_submit()

        path = assert_patch(context.quote_live)
        {:ok, accept_live, html} = live(context.conn, path)

        {:ok, Map.merge(context, %{accept_live: accept_live, html: html})}
      end

      then_ "the total shown at acceptance is exactly $195 with no added fees", context do
        assert context.html =~ "$195.00"
        refute has_element?(context.accept_live, "[data-test='added-fee']")

        {:ok, context}
      end
    end
  end
end
