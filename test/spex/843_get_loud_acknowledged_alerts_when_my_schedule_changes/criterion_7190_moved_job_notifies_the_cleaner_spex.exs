defmodule CleanerCrmSpex.Story843.Criterion7190Spex do
  @moduledoc """
  Story 843 — Get loud, acknowledged alerts when my schedule changes
  Criterion 7190 — Moving a job's time on the schedule board pushes the
  reassigned cleaner a notification describing the old and new times.

  Assumes the board exposes a per-job start-time control
  (`[data-test='job-<id>-start-time-input']`, `phx-change="reschedule_job"`)
  alongside the cleaner-select control already assumed by story 834's
  criterion 7170.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a moved job notifies the assigned cleaner" do
    scenario "moved job notifies the cleaner" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "I am a cleaner with a job scheduled today at 1:00 PM", context do
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
            start_time: ~T[13:00:00],
            end_time: ~T[14:30:00]
          })

        {:ok, Map.merge(context, %{cleaner: cleaner, cleaner_conn: cleaner_conn, job: job})}
      end

      when_ "the office moves that job to 3:00 PM", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/app/schedule")

        board_live
        |> element("[data-test='job-#{context.job.id}-start-time-input']")
        |> render_change(%{"start_time" => "15:00"})

        {:ok, context}
      end

      then_ "I receive a notification describing the change from 1:00 PM to 3:00 PM", context do
        {:ok, today_live, html} = live(context.cleaner_conn, ~p"/app/field")

        assert has_element?(today_live, "[data-test='schedule-alert']")
        assert html =~ "1:00 PM"
        assert html =~ "3:00 PM"

        {:ok, context}
      end
    end
  end
end
