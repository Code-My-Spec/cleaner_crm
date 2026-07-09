defmodule CleanerCrmSpex.Story849.Criterion7231Spex do
  @moduledoc """
  Story 849 — Accept a quote and book online with card on file
  Criterion 7231 — Client views and agrees to the cancellation policy
  before confirming: checking the agreement (24-hour notice and fee)
  lets the client proceed to payment.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "agreeing to the cancellation policy allows proceeding to payment" do
    scenario "client views and agrees to the cancellation policy before confirming" do
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

        assert render(accept_live) =~ "24-hour"

        {:ok, Map.merge(context, %{lead: lead, accept_live: accept_live})}
      end

      when_ "the cancellation policy (24-hour notice and fee) is displayed and the client checks agreement",
            context do
        html =
          context.accept_live
          |> form("[data-test='confirmation-form']",
            booking: %{policy_agreed: "true", payment_method: "pm_card_visa"}
          )
          |> render_submit()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the client is allowed to proceed to payment", context do
        refute has_element?(context.accept_live, "[data-test='policy-required-error']")
        assert has_element?(context.accept_live, "[data-test='payment-pending']")

        {:ok, context}
      end
    end
  end
end
