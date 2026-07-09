defmodule CleanerCrmSpex.Story843.Criterion7200Spex do
  @moduledoc """
  Story 843 — Get loud, acknowledged alerts when my schedule changes
  Criterion 7200 — Never-acknowledged same-day change escalates

  The push itself is covered end-to-end by criteria 7190/7191, so the
  pending notification is seeded directly via
  `CleanerCrmSpex.Fixtures.schedule_change_notification_fixture/4`
  with `pushed_at` pinned to 10 minutes ago — the default escalation
  window from the rule. There is no user action for "the escalation
  window elapses": by the time `then_` asserts, any conforming
  implementation's periodic escalation check has already fired, the
  same pinned-clock pattern story 837's criterion 7183 uses for its
  lead-time trigger.

  Assumes the board's per-job acknowledgment-status control
  (`[data-test='job-<id>-ack-status']`) renders "Escalated" once the
  window elapses, and a per-job notification-channel control
  (`[data-test='job-<id>-notification-channel']`) reflects the
  fallback channel used for the re-send.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a same-day change left unacknowledged past the escalation window escalates" do
    scenario "never-acknowledged same-day change escalates" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "the office pushed a same-day schedule change to me 10 minutes ago", context do
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
          Fixtures.schedule_change_notification_fixture(context.scope, cleaner, job, %{
            pushed_at: DateTime.add(DateTime.utc_now(), -600, :second)
          })

        {:ok,
         Map.merge(context, %{
           cleaner: cleaner,
           cleaner_conn: cleaner_conn,
           job: job,
           notification: notification
         })}
      end

      given_ "I still have not acknowledged it", context do
        {:ok, context}
      end

      when_ "the escalation window elapses", context do
        {:ok, context}
      end

      then_ "the notification is re-sent to me via the fallback channel", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/schedule")

        assert has_element?(
                 board_live,
                 "[data-test='job-#{context.job.id}-notification-channel']",
                 "SMS"
               )

        {:ok, Map.put(context, :board_live, board_live)}
      end

      then_ "the change is flagged to the office as unacknowledged and escalated", context do
        assert has_element?(
                 context.board_live,
                 "[data-test='job-#{context.job.id}-ack-status']",
                 "Escalated"
               )

        {:ok, context}
      end
    end
  end
end
