defmodule CleanerCrmSpex.Story843.Criterion7194Spex do
  @moduledoc """
  Story 843 — Get loud, acknowledged alerts when my schedule changes
  Criterion 7194 — Unacknowledged change keeps prompting

  "Dismiss it or close the app without acknowledging" is modeled as
  simply not tapping acknowledge — the cleaner opens the day view,
  takes no action on the alert, and later reopens it. The push itself
  is covered end-to-end by criteria 7190/7191, so the pending
  notification is seeded directly via
  `CleanerCrmSpex.Fixtures.schedule_change_notification_fixture/4`.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "an unacknowledged schedule change keeps prompting the cleaner" do
    scenario "unacknowledged change keeps prompting" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "I have a schedule-change notification I have not acknowledged", context do
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

      when_ "I close the app without acknowledging it", context do
        {:ok, _today_live, _html} = live(context.cleaner_conn, ~p"/app/field")

        {:ok, context}
      end

      then_ "the change remains pending", context do
        {:ok, today_live, _html} = live(context.cleaner_conn, ~p"/app/field")

        assert has_element?(today_live, "[data-test='schedule-alert-#{context.notification.id}']")

        {:ok, context}
      end

      then_ "I am prompted about it again when I next open the app", context do
        {:ok, today_live, _html} = live(context.cleaner_conn, ~p"/app/field")

        assert has_element?(today_live, "[data-test='schedule-alert-#{context.notification.id}']")

        {:ok, context}
      end
    end
  end
end
