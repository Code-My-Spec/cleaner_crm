defmodule CleanerCrmSpex.Story849.Criterion7232Spex do
  @moduledoc """
  Story 849 — Accept a quote and book online with card on file
  Criterion 7232 — Booking is blocked without cancellation policy
  agreement: trying to confirm without checking agreement leaves the
  booking unconfirmed and prompts the client to agree first.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "confirming without agreeing to the cancellation policy is blocked" do
    scenario "booking is blocked without cancellation policy agreement" do
      given_ "the client has selected a slot and reached the confirmation step", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        lead = Fixtures.lead_fixture(scope, %{total_cents: 19_500})

        {:ok, accept_live, _html} = live(context.conn, ~p"/book/accept/#{lead.acceptance_token}")

        accept_live
        |> form("[data-test='slot-form']",
          booking: %{scheduled_date: Date.add(Date.utc_today(), 10), start_time: "09:00"}
        )
        |> render_submit()

        {:ok, Map.merge(context, %{lead: lead, accept_live: accept_live})}
      end

      when_ "the client tries to confirm without checking the cancellation policy agreement",
            context do
        html =
          context.accept_live
          |> form("[data-test='confirmation-form']",
            booking: %{policy_agreed: "false", payment_method: "pm_card_visa"}
          )
          |> render_submit()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the booking is not confirmed and the client is prompted to agree first", context do
        assert has_element?(context.accept_live, "[data-test='policy-required-error']")
        refute has_element?(context.accept_live, "[data-test='payment-pending']")
        refute has_element?(context.accept_live, "[data-test='booking-confirmed']")

        {:ok, context}
      end
    end
  end
end
