defmodule CleanerCrmSpex.Story849.Criterion7230Spex do
  @moduledoc """
  Story 849 — Accept a quote and book online with card on file
  Criterion 7230 — Selected slot becomes unavailable before
  confirmation: if another booking claims the same slot before this
  client confirms, the confirmation is blocked and no charge is made.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a slot claimed by another booking blocks confirmation" do
    scenario "selected slot becomes unavailable before confirmation" do
      given_ "a client has selected a time slot but another booking claims it first", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})

        lead = Fixtures.lead_fixture(scope, %{total_cents: 19_500})

        {:ok, accept_live, _html} = live(context.conn, ~p"/book/accept/#{lead.acceptance_token}")

        scheduled_date = Date.add(Date.utc_today(), 10)

        accept_live
        |> form("[data-test='slot-form']",
          booking: %{scheduled_date: scheduled_date, start_time: "09:00"}
        )
        |> render_submit()

        other_client = Fixtures.client_fixture(scope, %{name: "Other Client"})

        Fixtures.job_fixture(scope, other_client, %{
          scheduled_date: scheduled_date,
          start_time: ~T[09:00:00],
          end_time: ~T[11:00:00]
        })

        {:ok, Map.merge(context, %{lead: lead, accept_live: accept_live})}
      end

      when_ "the client attempts to confirm the booking", context do
        html =
          context.accept_live
          |> form("[data-test='confirmation-form']",
            booking: %{policy_agreed: "true", payment_method: "pm_card_visa"}
          )
          |> render_submit()

        {:ok, Map.put(context, :html, html)}
      end

      then_ "the booking is blocked with a message to pick another slot and no charge is made",
            context do
        assert has_element?(context.accept_live, "[data-test='slot-unavailable-error']")
        refute has_element?(context.accept_live, "[data-test='payment-pending']")
        refute has_element?(context.accept_live, "[data-test='booking-confirmed']")

        {:ok, context}
      end
    end
  end
end
