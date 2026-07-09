defmodule CleanerCrmSpex.Story834.Criterion7170Spex do
  @moduledoc """
  Story 834 — Dispatch from a single weekly schedule board
  Criterion 7170 — Reassigning a job to another cleaner on the board
  updates that job's assignment immediately.

  Assumes each job card exposes a per-job cleaner-select control
  (`[data-test='job-<id>-cleaner-select']`, `phx-change="reassign_job"`)
  since drag-and-drop isn't drivable through LiveViewTest.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the owner reassigns a job to another cleaner" do
    scenario "moving a job from Ana to Ben updates the assignment" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        scope = %{scope | active_account: account, active_account_id: account.id}
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a Wednesday job is assigned to cleaner Ana", context do
        ana =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "ana-#{System.unique_integer([:positive])}@example.com"
          })

        ben =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "ben-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope, %{name: "Wednesday client"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: ana.id,
            scheduled_date: wednesday(),
            start_time: ~T[13:00:00],
            end_time: ~T[15:00:00]
          })

        {:ok, Map.merge(context, %{ana: ana, ben: ben, job: job})}
      end

      when_ "the owner moves the job to cleaner Ben on the board", context do
        {:ok, view, _html} = live(context.conn, ~p"/schedule")

        view
        |> element("[data-test='job-#{context.job.id}-cleaner-select']")
        |> render_change(%{"cleaner_id" => to_string(context.ben.id)})

        {:ok, Map.put(context, :view, view)}
      end

      then_ "the job's assigned cleaner becomes Ben", context do
        assert has_element?(
                 context.view,
                 "[data-test='cleaner-column-#{context.ben.id}'] [data-test='job-#{context.job.id}']"
               )

        {:ok, context}
      end

      then_ "the job no longer appears under Ana", context do
        refute has_element?(
                 context.view,
                 "[data-test='cleaner-column-#{context.ana.id}'] [data-test='job-#{context.job.id}']"
               )

        {:ok, context}
      end
    end
  end

  defp wednesday do
    today = Date.utc_today()
    monday = Date.add(today, -(Date.day_of_week(today) - 1))
    Date.add(monday, 2)
  end
end
