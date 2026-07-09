defmodule CleanerCrmSpex.Story840.Criterion7195Spex do
  @moduledoc """
  Story 840 — See an audit trail of schedule and record changes
  Criterion 7195 — Price change records old and new value: the audit
  entry shows the price field's before/after values and leaves fields
  that did not change out of the entry entirely.

  Assumes `CleanerCrmWeb.ScheduleLive.JobFormComponent` (opened from
  the board at `/schedule`) exposes a `[data-test='job-<id>-edit-button']`
  trigger and a `[data-test='job-form']` submitted via `render_submit`
  with an `agreed_price` field. Assumes `CleanerCrmWeb.AuditLive`
  (`/audit`) renders one `"<Field label>: <old> → <new>"` line per
  changed field on each `[data-test='audit-entries']` entry, omitting
  any field whose value did not change.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a price change records the old and new value" do
    scenario "raising the price from $120 to $140 is recorded precisely" do
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

      given_ "a client's recurring job is priced at $120", context do
        client = Fixtures.client_fixture(context.scope, %{name: "Price client"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            agreed_price: Decimal.new("120.00"),
            scheduled_date: next_week_thursday(),
            start_time: ~T[10:00:00],
            end_time: ~T[12:00:00]
          })

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "Dana changes the price to $140", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/schedule")

        board_live
        |> element("[data-test='job-#{context.job.id}-edit-button']")
        |> render_click()

        board_live
        |> form("[data-test='job-form']", job: %{agreed_price: "140.00"})
        |> render_submit()

        {:ok, Map.put(context, :board_live, board_live)}
      end

      then_ "the audit entry shows the price changed from $120.00 to $140.00", context do
        {:ok, _audit_live, html} = live(context.conn, ~p"/audit")

        assert html =~ "Price: $120.00 → $140.00"

        {:ok, context}
      end

      then_ "the entry leaves the untouched schedule fields out of the entry", context do
        {:ok, _audit_live, html} = live(context.conn, ~p"/audit")

        refute html =~ "Scheduled date:"
        refute html =~ "Start time:"

        {:ok, context}
      end
    end
  end

  defp next_week_thursday do
    today = Date.utc_today()
    monday = Date.add(today, -(Date.day_of_week(today) - 1))
    Date.add(monday, 10)
  end
end
