defmodule CleanerCrmSpex.Story840.Criterion7201Spex do
  @moduledoc """
  Story 840 — See an audit trail of schedule and record changes
  Criterion 7201 — Owner filters the trail to find who moved a job: the
  owner narrows the audit trail to one record over a date range and
  sees which user deleted or moved it, and when.

  Assumes `CleanerCrmWeb.ScheduleLive.Board` (`/schedule`) exposes a
  `[data-test='job-<id>-delete-button']` per job card. Assumes
  `CleanerCrmWeb.AuditLive` (`/audit`) renders a
  `[data-test='audit-filter-form']` with `subject_id`, `date_from`, and
  `date_to` fields (submitted via `render_change`) that narrows the
  `[data-test='audit-entries']` list to matching entries.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "owner filters the trail to find who moved a job" do
    scenario "filtering to the vanished Friday job over the past week surfaces who deleted it" do
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

      given_ "a Friday job for a client exists on the schedule", context do
        client = Fixtures.client_fixture(context.scope, %{name: "Friday client"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            scheduled_date: friday(),
            start_time: ~T[09:00:00],
            end_time: ~T[11:00:00]
          })

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      given_ "the client complains the job vanished, because Dana deleted it from the board",
             context do
        {:ok, board_live, _html} = live(context.conn, ~p"/schedule")

        board_live
        |> element("[data-test='job-#{context.job.id}-delete-button']")
        |> render_click()

        {:ok, context}
      end

      when_ "the owner filters the audit trail to that job over the past week", context do
        {:ok, audit_live, _html} = live(context.conn, ~p"/audit")

        audit_live
        |> form("[data-test='audit-filter-form']",
          filter: %{
            subject_id: to_string(context.job.id),
            date_from: Date.to_iso8601(Date.add(Date.utc_today(), -7)),
            date_to: Date.to_iso8601(Date.utc_today())
          }
        )
        |> render_change()

        {:ok, Map.put(context, :audit_live, audit_live)}
      end

      then_ "the owner sees which user deleted the job and when", context do
        html = render(context.audit_live)

        assert html =~ context.user.email
        assert html =~ "deleted"
        assert html =~ "Friday client"
        assert html =~ Date.to_iso8601(Date.utc_today())

        {:ok, context}
      end
    end
  end

  defp friday do
    today = Date.utc_today()
    monday = Date.add(today, -(Date.day_of_week(today) - 1))
    Date.add(monday, 4)
  end
end
