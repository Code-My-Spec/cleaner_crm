defmodule CleanerCrmSpex.Story849.Criterion7228Spex do
  @moduledoc """
  Story 849 — Accept a quote and book online with card on file
  Criterion 7228 — Client selects an open slot and proceeds to
  review: picking an available date and time advances the booking
  flow to cancellation policy and payment.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "selecting an open slot advances to cancellation policy and payment" do
    scenario "client selects an open slot and proceeds to review" do
      given_ "a client has an accepted instant quote and the business has open slots", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        lead =
          Fixtures.lead_fixture(scope, %{
            total_cents: 19_500,
            client_name: "Dana Prescott",
            client_email: "dana@example.com"
          })

        {:ok, accept_live, _html} = live(context.conn, ~p"/book/accept/#{lead.acceptance_token}")

        {:ok, Map.merge(context, %{lead: lead, accept_live: accept_live})}
      end

      when_ "the client selects an available date and time", context do
        html =
          context.accept_live
          |> form("[data-test='slot-form']",
            booking: %{scheduled_date: Date.add(Date.utc_today(), 10), start_time: "09:00"}
          )
          |> render_submit()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the booking flow proceeds to cancellation policy and payment", context do
        assert has_element?(context.accept_live, "[data-test='confirmation-form']")
        assert has_element?(context.accept_live, "[data-test='policy-agreement-checkbox']")

        {:ok, context}
      end
    end
  end
end
