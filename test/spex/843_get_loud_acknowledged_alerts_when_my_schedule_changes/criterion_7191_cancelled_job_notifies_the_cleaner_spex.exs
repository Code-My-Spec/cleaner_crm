defmodule CleanerCrmSpex.Story843.Criterion7191Spex do
  @moduledoc """
  Story 843 — Get loud, acknowledged alerts when my schedule changes
  Criterion 7191 — Cancelling a job on the schedule board pushes the
  assigned cleaner a notification that the job was cancelled.

  Assumes the board exposes a per-job cancel control
  (`[data-test='job-<id>-cancel-button']`, `phx-click="cancel_job"`).
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cancelled job notifies the assigned cleaner" do
    scenario "cancelled job notifies the cleaner" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "I have a job scheduled for later today", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        cleaner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), cleaner)
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            scheduled_date: Date.utc_today(),
            start_time: ~T[16:00:00],
            end_time: ~T[17:30:00]
          })

        {:ok, Map.merge(context, %{cleaner: cleaner, cleaner_conn: cleaner_conn, job: job})}
      end

      when_ "the office cancels that job", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/schedule")

        board_live
        |> element("[data-test='job-#{context.job.id}-cancel-button']")
        |> render_click()

        {:ok, context}
      end

      then_ "I receive a notification that the job has been cancelled", context do
        {:ok, today_live, html} = live(context.cleaner_conn, ~p"/field")

        assert has_element?(today_live, "[data-test='schedule-alert']")
        assert html =~ "Cancelled"

        {:ok, context}
      end
    end
  end
end
