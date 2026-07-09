defmodule CleanerCrmSpex.Story840.Criterion7198Spex do
  @moduledoc """
  Story 840 — See an audit trail of schedule and record changes
  Criterion 7198 — Nobody can alter or delete an audit entry: the
  audit log is append-only, so the audit UI must expose no edit or
  delete affordance for any entry, and the entry must remain visible.

  Assumes `CleanerCrmWeb.ScheduleLive.JobFormComponent` (opened from
  the board at `/app/schedule`) exposes a `[data-test='job-<id>-edit-button']`
  trigger and a `[data-test='job-form']` submitted via `render_submit`.
  Assumes `CleanerCrmWeb.AuditLive` (`/app/audit`) renders every entry
  inside a `[data-test='audit-entries']` container and never renders an
  "Edit" or "Delete" button/link for an entry, regardless of who is
  viewing — there being no such control is the entire point of this
  criterion.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "nobody can alter or delete an audit entry" do
    scenario "the owner finds no way to edit or delete a disputed schedule change" do
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

      given_ "a disputed schedule change was made and logged", context do
        client = Fixtures.client_fixture(context.scope, %{name: "Disputed client"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            scheduled_date: next_week_tuesday(),
            start_time: ~T[09:00:00],
            end_time: ~T[11:00:00]
          })

        {:ok, board_live, _html} = live(context.conn, ~p"/app/schedule")

        board_live
        |> element("[data-test='job-#{job.id}-edit-button']")
        |> render_click()

        board_live
        |> form("[data-test='job-form']",
          job: %{scheduled_date: Date.to_iso8601(Date.add(next_week_tuesday(), 1))}
        )
        |> render_submit()

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "the owner opens the audit trail looking for a way to edit or delete that entry",
            context do
        {:ok, audit_live, _html} = live(context.conn, ~p"/app/audit")

        {:ok, Map.put(context, :audit_live, audit_live)}
      end

      then_ "the entry is visible in the trail", context do
        assert has_element?(context.audit_live, "[data-test='audit-entries']")
        assert render(context.audit_live) =~ "rescheduled"

        {:ok, context}
      end

      then_ "no edit or delete control is offered for it", context do
        refute has_element?(context.audit_live, "[data-test='audit-entries'] button", "Edit")
        refute has_element?(context.audit_live, "[data-test='audit-entries'] a", "Edit")
        refute has_element?(context.audit_live, "[data-test='audit-entries'] button", "Delete")
        refute has_element?(context.audit_live, "[data-test='audit-entries'] a", "Delete")

        {:ok, context}
      end
    end
  end

  defp next_week_tuesday do
    today = Date.utc_today()
    monday = Date.add(today, -(Date.day_of_week(today) - 1))
    Date.add(monday, 8)
  end
end
