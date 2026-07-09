defmodule CleanerCrmSpex.Story834.Criterion7177Spex do
  @moduledoc """
  Story 834 — Dispatch from a single weekly schedule board
  Criterion 7177 — A job reassigned on the board is reflected on the
  newly assigned cleaner's own schedule.

  Story 834's only linked surface is `ScheduleLive.Board`; the
  cleaner-facing `FieldLive` (stories 841-845) is a day view, not a
  week view, and `/app/schedule` is an office-only surface a cleaner like
  Ben cannot open himself. "Ben's schedule reflects the reassignment"
  is modeled here as a second, independent office session (a fresh
  connection, not the reassigning owner's still-open LiveView)
  reloading `/app/schedule` and finding the job under Ben's column —
  proving the reassignment is durable server-side state rather than
  optimistic UI on the original socket.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "reassignment reaches the newly assigned cleaner's schedule" do
    scenario "Ben sees the job that was moved from Ana, and Ana no longer does" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        scope = %{scope | active_account: account, active_account_id: account.id}
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a job is reassigned from Ana to Ben on the board", context do
        ana =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "ana-#{System.unique_integer([:positive])}@example.com"
          })

        ben =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "ben-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope, %{name: "Reassigned client"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: ana.id,
            scheduled_date: Date.utc_today(),
            start_time: ~T[09:00:00],
            end_time: ~T[11:00:00]
          })

        {:ok, owner_view, _html} = live(context.conn, ~p"/app/schedule")

        owner_view
        |> element("[data-test='job-#{job.id}-cleaner-select']")
        |> render_change(%{"cleaner_id" => to_string(ben.id)})

        {:ok, Map.merge(context, %{ana: ana, ben: ben, job: job})}
      end

      when_ "the board is reloaded in a fresh office session", context do
        second_office_conn = Fixtures.log_in_user(build_conn(), context.user)
        {:ok, board_view, _html} = live(second_office_conn, ~p"/app/schedule")

        {:ok, Map.put(context, :board_view, board_view)}
      end

      then_ "the reassigned job appears under Ben's column", context do
        assert has_element?(
                 context.board_view,
                 "[data-test='cleaner-column-#{context.ben.id}'] [data-test='job-#{context.job.id}']"
               )

        {:ok, context}
      end

      then_ "it is gone from Ana's schedule", context do
        refute has_element?(
                 context.board_view,
                 "[data-test='cleaner-column-#{context.ana.id}'] [data-test='job-#{context.job.id}']"
               )

        {:ok, context}
      end
    end
  end
end
