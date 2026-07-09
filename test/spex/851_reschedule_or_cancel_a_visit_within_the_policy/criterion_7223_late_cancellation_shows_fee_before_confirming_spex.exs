defmodule CleanerCrmSpex.Story851.Criterion7223Spex do
  @moduledoc """
  Story 851 — Reschedule or cancel a visit within the policy
  Criterion 7223 — Late cancellation shows fee before confirming

  Assumes `PortalLive.Visit` exposes a two-step cancel control (never
  a native `data-confirm` dialog, which `LiveViewTest` can't drive):
  clicking `[data-test='cancel-visit-button']` reveals a
  `[data-test='cancellation-fee-notice']` alongside
  `[data-test='confirm-cancel-button']` before anything is cancelled.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "cancelling within the notice window shows the late fee before the client confirms" do
    scenario "late cancellation shows fee before confirming" do
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

      given_ "I have a visit scheduled for tomorrow, inside the notice window", context do
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            scheduled_date: Date.add(Date.utc_today(), 1),
            start_time: ~T[10:00:00],
            end_time: ~T[12:00:00]
          })

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok, Map.merge(context, %{client: client, job: job, portal_conn: portal_conn})}
      end

      when_ "I start cancelling the visit", context do
        {:ok, visit_live, _html} =
          live(context.portal_conn, ~p"/portal/visits/#{context.job.id}")

        visit_live
        |> element("[data-test='cancel-visit-button']")
        |> render_click()

        {:ok, Map.put(context, :visit_live, visit_live)}
      end

      then_ "I see the late cancellation fee before I confirm", context do
        assert has_element?(context.visit_live, "[data-test='cancellation-fee-notice']", "$25.00")
        assert has_element?(context.visit_live, "[data-test='confirm-cancel-button']")

        {:ok, context}
      end
    end
  end
end
