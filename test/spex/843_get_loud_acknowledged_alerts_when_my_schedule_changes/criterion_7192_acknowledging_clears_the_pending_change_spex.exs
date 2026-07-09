defmodule CleanerCrmSpex.Story843.Criterion7192Spex do
  @moduledoc """
  Story 843 — Get loud, acknowledged alerts when my schedule changes
  Criterion 7192 — Acknowledging clears the pending change

  The push itself is covered end-to-end by criteria 7190/7191; this
  spec's subject is the acknowledge action, so the already-pending
  notification is seeded directly via
  `CleanerCrmSpex.Fixtures.schedule_change_notification_fixture/4`.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "acknowledging a pending schedule change clears it" do
    scenario "acknowledging clears the pending change" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "I have a pending schedule-change notification", context do
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
            change_summary: "Job moved to 3:00 PM"
          })

        {:ok,
         Map.merge(context, %{
           cleaner: cleaner,
           cleaner_conn: cleaner_conn,
           job: job,
           notification: notification
         })}
      end

      when_ "I tap acknowledge on it", context do
        {:ok, today_live, _html} = live(context.cleaner_conn, ~p"/app/field")

        today_live
        |> element("[data-test='schedule-alert-#{context.notification.id}-acknowledge-button']")
        |> render_click()

        {:ok, Map.put(context, :today_live, today_live)}
      end

      then_ "the change is marked acknowledged", context do
        refute has_element?(
                 context.today_live,
                 "[data-test='schedule-alert-#{context.notification.id}']"
               )

        assert has_element?(context.today_live, "[data-test='field-today']")

        {:ok, context}
      end

      then_ "it stops prompting me", context do
        {:ok, today_live, html} = live(context.cleaner_conn, ~p"/app/field")

        refute html =~ "schedule-alert-#{context.notification.id}"
        assert has_element?(today_live, "[data-test='field-today']")

        {:ok, context}
      end
    end
  end
end
