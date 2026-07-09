defmodule CleanerCrmSpex.Story840.Criterion7193Spex do
  @moduledoc """
  Story 840 — See an audit trail of schedule and record changes
  Criterion 7193 — Office staff reschedules a job and it is logged: an
  audit entry records who moved the job, the old and new times, and
  the timestamp of the change.

  Assumes `CleanerCrmWeb.ScheduleLive.JobFormComponent` (per the
  project's architecture spec, opened from the board at `/schedule`)
  exposes a `[data-test='job-<id>-edit-button']` trigger and a
  `[data-test='job-form']` submitted via `render_submit` with
  `scheduled_date`/`start_time`/`end_time` fields. Assumes
  `CleanerCrmWeb.AuditLive` (`/audit`) renders a
  `[data-test='audit-entries']` list where each entry shows its actor,
  action, one `"<Field label>: <old> → <new>"` line per changed field,
  and today's date as its timestamp.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "office staff reschedules a job and it is logged" do
    scenario "moving a job from Tuesday 9:00 to Wednesday 1:00 pm is recorded" do
      given_ "office staffer Dana is logged in with an active account", context do
        user =
          Fixtures.user_fixture(%{
            email: "dana-#{System.unique_integer([:positive])}@example.com"
          })

        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a job is scheduled for Tuesday at 9:00 am", context do
        client = Fixtures.client_fixture(context.scope, %{name: "Tuesday client"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            scheduled_date: tuesday(),
            start_time: ~T[09:00:00],
            end_time: ~T[11:00:00]
          })

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "Dana moves the job to Wednesday at 1:00 pm", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/schedule")

        board_live
        |> element("[data-test='job-#{context.job.id}-edit-button']")
        |> render_click()

        board_live
        |> form("[data-test='job-form']",
          job: %{
            scheduled_date: Date.to_iso8601(wednesday()),
            start_time: "13:00",
            end_time: "15:00"
          }
        )
        |> render_submit()

        {:ok, Map.put(context, :board_live, board_live)}
      end

      then_ "an audit entry names Dana as the one who rescheduled the job", context do
        {:ok, _audit_live, html} = live(context.conn, ~p"/audit")

        assert html =~ context.user.email
        assert html =~ "rescheduled"

        {:ok, context}
      end

      then_ "the audit entry records the old and new times and the timestamp of the change",
            context do
        {:ok, _audit_live, html} = live(context.conn, ~p"/audit")

        assert html =~
                 "Scheduled date: #{Date.to_iso8601(tuesday())} → #{Date.to_iso8601(wednesday())}"

        assert html =~ "Start time: 09:00:00 → 13:00:00"
        assert html =~ Date.to_iso8601(Date.utc_today())

        {:ok, context}
      end
    end
  end

  defp tuesday do
    monday = week_monday()
    Date.add(monday, 1)
  end

  defp wednesday do
    monday = week_monday()
    Date.add(monday, 2)
  end

  defp week_monday do
    today = Date.utc_today()
    Date.add(today, -(Date.day_of_week(today) - 1))
  end
end
