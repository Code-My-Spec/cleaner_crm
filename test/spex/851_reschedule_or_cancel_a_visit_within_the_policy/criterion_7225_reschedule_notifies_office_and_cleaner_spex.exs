defmodule CleanerCrmSpex.Story851.Criterion7225Spex do
  @moduledoc """
  Story 851 — Reschedule or cancel a visit within the policy
  Criterion 7225 — Reschedule notifies office and cleaner

  A portal reschedule is expected to push the same `:schedule_change`
  notification kind story 843's board-driven reschedule does (route
  contract: "changes create schedule-change notifications (existing
  Notifications context) for the assigned cleaner"), so this reuses
  the observation points criteria 7190 and 7197 already establish:
  the cleaner's `[data-test='schedule-alert']` on `FieldLive.Today`,
  and the office's `[data-test='job-<id>-ack-status']` on
  `ScheduleLive.Board`.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "rescheduling from the portal notifies the assigned cleaner and shows the office it's unacknowledged" do
    scenario "reschedule notifies office and cleaner" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "I have an upcoming visit assigned to a cleaner", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        cleaner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), cleaner)
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            scheduled_date: Date.add(Date.utc_today(), 7),
            start_time: ~T[13:00:00],
            end_time: ~T[14:30:00]
          })

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok,
         Map.merge(context, %{
           cleaner: cleaner,
           cleaner_conn: cleaner_conn,
           client: client,
           job: job,
           portal_conn: portal_conn
         })}
      end

      when_ "I reschedule the visit to a new time", context do
        {:ok, visit_live, _html} =
          live(context.portal_conn, ~p"/portal/visits/#{context.job.id}")

        visit_live
        |> form("[data-test='reschedule-form']",
          visit: %{date: Date.add(Date.utc_today(), 7), start_time: "15:00"}
        )
        |> render_submit()

        {:ok, context}
      end

      then_ "the assigned cleaner receives a schedule-change alert", context do
        {:ok, today_live, html} = live(context.cleaner_conn, ~p"/app/field")

        assert has_element?(today_live, "[data-test='schedule-alert']")
        assert html =~ "1:00 PM"
        assert html =~ "3:00 PM"

        {:ok, context}
      end

      then_ "the office sees it as unacknowledged on the schedule board", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/app/schedule")

        assert has_element?(
                 board_live,
                 "[data-test='job-#{context.job.id}-ack-status']",
                 "Unacknowledged"
               )

        {:ok, context}
      end
    end
  end
end
