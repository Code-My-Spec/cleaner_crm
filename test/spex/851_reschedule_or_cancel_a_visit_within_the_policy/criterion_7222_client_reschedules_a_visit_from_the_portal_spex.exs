defmodule CleanerCrmSpex.Story851.Criterion7222Spex do
  @moduledoc """
  Story 851 — Reschedule or cancel a visit within the policy
  Criterion 7222 — Client reschedules a visit from the portal

  Assumes `PortalLive.Visit` at `/portal/visits/:id` exposes a
  reschedule form (`[data-test='reschedule-form']`, fields
  `visit[date]` and `visit[start_time]`) that updates the visit's own
  schedule in place.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a client reschedules an upcoming visit from the portal" do
    scenario "client reschedules a visit from the portal" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "I have an upcoming visit well within the notice window", context do
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            scheduled_date: Date.add(Date.utc_today(), 7),
            start_time: ~T[10:00:00],
            end_time: ~T[12:00:00]
          })

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok, Map.merge(context, %{client: client, job: job, portal_conn: portal_conn})}
      end

      when_ "I reschedule it to a new date and time", context do
        {:ok, visit_live, _html} =
          live(context.portal_conn, ~p"/portal/visits/#{context.job.id}")

        visit_live
        |> form("[data-test='reschedule-form']",
          visit: %{date: Date.add(Date.utc_today(), 10), start_time: "14:00"}
        )
        |> render_submit()

        {:ok, Map.put(context, :visit_live, visit_live)}
      end

      then_ "the visit shows the new date and time", context do
        assert render(context.visit_live) =~ "2:00 PM"

        {:ok, context}
      end
    end
  end
end
