defmodule CleanerCrmSpex.Story834.Criterion7173Spex do
  @moduledoc """
  Story 834 — Dispatch from a single weekly schedule board
  Criterion 7173 — The board blocks assigning a job to a cleaner who
  already has an overlapping job at that time.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the board blocks a conflicting reassignment" do
    scenario "moving an overlapping job onto Ben is rejected" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        scope = %{scope | active_account: account, active_account_id: account.id}
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "cleaner Ben already has a job from 10am to 12pm Wednesday", context do
        ana =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "ana-#{System.unique_integer([:positive])}@example.com"
          })

        ben =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "ben-#{System.unique_integer([:positive])}@example.com"
          })

        bens_client = Fixtures.client_fixture(context.scope, %{name: "Ben's existing client"})

        _bens_existing_job =
          Fixtures.job_fixture(context.scope, bens_client, %{
            cleaner_id: ben.id,
            scheduled_date: wednesday(),
            start_time: ~T[10:00:00],
            end_time: ~T[12:00:00]
          })

        anas_client = Fixtures.client_fixture(context.scope, %{name: "11am client"})

        eleven_am_job =
          Fixtures.job_fixture(context.scope, anas_client, %{
            cleaner_id: ana.id,
            scheduled_date: wednesday(),
            start_time: ~T[11:00:00],
            end_time: ~T[12:00:00]
          })

        {:ok, Map.merge(context, %{ana: ana, ben: ben, job: eleven_am_job})}
      end

      when_ "the owner tries to move the 11am Wednesday job onto Ben", context do
        {:ok, view, _html} = live(context.conn, ~p"/app/schedule")

        view
        |> element("[data-test='job-#{context.job.id}-cleaner-select']")
        |> render_change(%{"cleaner_id" => to_string(context.ben.id)})

        {:ok, Map.put(context, :view, view)}
      end

      then_ "the board rejects the move and keeps the job on its original cleaner", context do
        assert has_element?(
                 context.view,
                 "[data-test='cleaner-column-#{context.ana.id}'] [data-test='job-#{context.job.id}']"
               )

        refute has_element?(
                 context.view,
                 "[data-test='cleaner-column-#{context.ben.id}'] [data-test='job-#{context.job.id}']"
               )

        {:ok, context}
      end

      then_ "the owner sees a conflict warning", context do
        assert has_element?(context.view, "[data-test='schedule-conflict-warning']")

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
