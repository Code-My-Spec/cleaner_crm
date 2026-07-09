defmodule CleanerCrmSpex.Story834.Criterion7175Spex do
  @moduledoc """
  Story 834 — Dispatch from a single weekly schedule board
  Criterion 7175 — Unassigned jobs for the week are visible on the
  board so the owner can dispatch them.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the owner dispatches an unassigned job from the board" do
    scenario "an unassigned Thursday job can be assigned from the board" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        scope = %{scope | active_account: account, active_account_id: account.id}
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a Thursday job has no cleaner assigned", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "chloe-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope, %{name: "Thursday client"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: nil,
            scheduled_date: thursday(),
            start_time: ~T[09:00:00],
            end_time: ~T[11:00:00]
          })

        {:ok, Map.merge(context, %{cleaner: cleaner, job: job})}
      end

      when_ "the owner opens the weekly board", context do
        {:ok, view, _html} = live(context.conn, ~p"/schedule")

        {:ok, Map.put(context, :view, view)}
      end

      then_ "the unassigned job is visible in an unassigned area", context do
        assert has_element?(
                 context.view,
                 "[data-test='unassigned-jobs'] [data-test='job-#{context.job.id}']"
               )

        {:ok, context}
      end

      when_ "the owner assigns it to an available cleaner from the board", context do
        context.view
        |> element("[data-test='job-#{context.job.id}-cleaner-select']")
        |> render_change(%{"cleaner_id" => to_string(context.cleaner.id)})

        {:ok, context}
      end

      then_ "the job moves out of the unassigned area onto that cleaner's column", context do
        refute has_element?(
                 context.view,
                 "[data-test='unassigned-jobs'] [data-test='job-#{context.job.id}']"
               )

        assert has_element?(
                 context.view,
                 "[data-test='cleaner-column-#{context.cleaner.id}'] [data-test='job-#{context.job.id}']"
               )

        {:ok, context}
      end
    end
  end

  defp thursday do
    today = Date.utc_today()
    monday = Date.add(today, -(Date.day_of_week(today) - 1))
    Date.add(monday, 3)
  end
end
