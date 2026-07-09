defmodule CleanerCrmSpex.Story851.Criterion7224Spex do
  @moduledoc """
  Story 851 — Reschedule or cancel a visit within the policy
  Criterion 7224 — On-time cancellation has no fee

  Assumes the same two-step cancel control as criterion 7223's spec:
  `[data-test='cancel-visit-button']` then
  `[data-test='confirm-cancel-button']`, with no
  `[data-test='cancellation-fee-notice']` rendered when the visit is
  outside the notice window.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "cancelling outside the notice window charges no fee" do
    scenario "on-time cancellation has no fee" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "the account has a 48-hour notice policy with a $25 late fee", context do
        Fixtures.cancellation_policy_fixture(context.scope, %{
          notice_window_hours: 48,
          late_fee_cents: 2_500,
          same_day_fee_cents: 5_000
        })

        {:ok, context}
      end

      given_ "I have a visit scheduled five days from now, outside the notice window", context do
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            scheduled_date: Date.add(Date.utc_today(), 5),
            start_time: ~T[10:00:00],
            end_time: ~T[12:00:00]
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

        refute has_element?(visit_live, "[data-test='cancellation-fee-notice']")

        visit_live
        |> element("[data-test='confirm-cancel-button']")
        |> render_click()

        {:ok, Map.put(context, :visit_live, visit_live)}
      end

      then_ "the visit is cancelled with no fee charged", context do
        html = render(context.visit_live)

        assert html =~ "Cancelled"
        refute html =~ ~r/fee/i

        {:ok, context}
      end
    end
  end
end
