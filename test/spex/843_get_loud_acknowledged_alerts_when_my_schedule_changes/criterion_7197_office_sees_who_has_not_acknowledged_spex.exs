defmodule CleanerCrmSpex.Story843.Criterion7197Spex do
  @moduledoc """
  Story 843 — Get loud, acknowledged alerts when my schedule changes
  Criterion 7197 — Office sees who has not acknowledged

  The push itself is covered end-to-end by criteria 7190/7191; this
  spec's subject is the board's acknowledgment-status visibility, so
  the already-pending notification is seeded directly via
  `CleanerCrmSpex.Fixtures.schedule_change_notification_fixture/4`.
  The scenario then re-drives the real acknowledge action on
  `FieldLive.Today` to observe the status flip on `ScheduleLive.Board`,
  since that flip is the criterion's own subject.

  Assumes the board shows a per-job acknowledgment-status control
  (`[data-test='job-<id>-ack-status']`) rendering "Unacknowledged" or
  "Acknowledged".
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the office sees per-job acknowledgment status flip as the cleaner acknowledges" do
    scenario "office sees who has not acknowledged" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "the office pushed a schedule change to a cleaner", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        cleaner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), cleaner)
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            scheduled_date: Date.utc_today()
          })

        notification =
          Fixtures.schedule_change_notification_fixture(context.scope, cleaner, job)

        {:ok,
         Map.merge(context, %{
           cleaner: cleaner,
           cleaner_conn: cleaner_conn,
           job: job,
           notification: notification
         })}
      end

      given_ "the cleaner has not acknowledged it", context do
        {:ok, context}
      end

      when_ "the office views the change", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/app/schedule")

        {:ok, Map.put(context, :board_live, board_live)}
      end

      then_ "it shows as unacknowledged for that cleaner", context do
        assert has_element?(
                 context.board_live,
                 "[data-test='job-#{context.job.id}-ack-status']",
                 "Unacknowledged"
               )

        {:ok, context}
      end

      when_ "the cleaner acknowledges the change", context do
        {:ok, today_live, _html} = live(context.cleaner_conn, ~p"/app/field")

        today_live
        |> element("[data-test='schedule-alert-#{context.notification.id}-acknowledge-button']")
        |> render_click()

        {:ok, context}
      end

      then_ "once the cleaner acknowledges, the office sees it flip to acknowledged", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/app/schedule")

        assert has_element?(
                 board_live,
                 "[data-test='job-#{context.job.id}-ack-status']",
                 "Acknowledged"
               )

        {:ok, context}
      end
    end
  end
end
