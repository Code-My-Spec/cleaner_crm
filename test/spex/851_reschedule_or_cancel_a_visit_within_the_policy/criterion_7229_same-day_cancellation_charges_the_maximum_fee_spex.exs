defmodule CleanerCrmSpex.Story851.Criterion7229Spex do
  @moduledoc """
  Story 851 — Reschedule or cancel a visit within the policy
  Criterion 7229 — Same-day cancellation charges the maximum fee

  Assumes the same two-step cancel control as criteria 7223/7224:
  `[data-test='cancel-visit-button']` then
  `[data-test='confirm-cancel-button']`, and that a completed
  same-day cancellation shows the charged fee via
  `[data-test='cancellation-fee-charged']`.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "cancelling a visit the same day charges the policy's maximum fee" do
    scenario "same-day cancellation charges the maximum fee" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "the account has a $25 late fee and a $50 same-day maximum fee", context do
        Fixtures.cancellation_policy_fixture(context.scope, %{
          notice_window_hours: 48,
          late_fee_cents: 2_500,
          same_day_fee_cents: 5_000
        })

        {:ok, context}
      end

      given_ "I have a visit scheduled for later today", context do
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            scheduled_date: Date.utc_today(),
            start_time: ~T[18:00:00],
            end_time: ~T[20:00:00]
          })

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok, Map.merge(context, %{client: client, job: job, portal_conn: portal_conn})}
      end

      when_ "I cancel the visit and confirm", context do
        {:ok, visit_live, _html} =
          live(context.portal_conn, ~p"/portal/visits/#{context.job.id}")

        visit_live
        |> element("[data-test='cancel-visit-button']")
        |> render_click()

        assert has_element?(visit_live, "[data-test='cancellation-fee-notice']", "$50.00")

        visit_live
        |> element("[data-test='confirm-cancel-button']")
        |> render_click()

        {:ok, Map.put(context, :visit_live, visit_live)}
      end

      then_ "the maximum same-day fee is charged", context do
        assert has_element?(
                 context.visit_live,
                 "[data-test='cancellation-fee-charged']",
                 "$50.00"
               )

        {:ok, context}
      end
    end
  end
end
