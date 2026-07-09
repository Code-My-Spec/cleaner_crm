defmodule CleanerCrmSpex.Story834.Criterion7167Spex do
  @moduledoc """
  Story 834 — Dispatch from a single weekly schedule board
  Criterion 7167 — See the whole week at a glance: the board shows
  every cleaner's jobs for the selected week on one screen.

  Assumes `CleanerCrmWeb.ScheduleLive.Board` (mounted at `/schedule`,
  per the project's BDD plan) renders a `[data-test='weekly-board']`
  container with one `[data-test='cleaner-column-<id>']` per cleaner,
  each containing `[data-test='job-<id>']` cards for that cleaner's
  jobs. Cleaners are seeded via `CleanerCrmSpex.Fixtures.cleaner_fixture/3`,
  added for this story since no creation flow covers cleaner
  assignment yet.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the owner sees the whole week at a glance" do
    scenario "the board shows all 4 cleaners and their jobs across the week" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        scope = %{scope | active_account: account, active_account_id: account.id}
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "the company has 4 cleaners with jobs scheduled this week", context do
        monday = week_monday()

        {cleaners, jobs} =
          ["Ana", "Ben", "Chloe", "Dana"]
          |> Enum.with_index()
          |> Enum.map(fn {name, offset} ->
            cleaner =
              Fixtures.cleaner_fixture(context.scope, context.account, %{
                email:
                  "#{String.downcase(name)}-#{System.unique_integer([:positive])}@example.com"
              })

            client = Fixtures.client_fixture(context.scope, %{name: "#{name}'s client"})

            job =
              Fixtures.job_fixture(context.scope, client, %{
                cleaner_id: cleaner.id,
                scheduled_date: Date.add(monday, offset),
                start_time: ~T[09:00:00],
                end_time: ~T[11:00:00]
              })

            {cleaner, job}
          end)
          |> Enum.unzip()

        {:ok, Map.merge(context, %{cleaners: cleaners, jobs: jobs})}
      end

      when_ "the owner opens the weekly board for that week", context do
        {:ok, view, _html} = live(context.conn, ~p"/schedule")

        {:ok, Map.put(context, :view, view)}
      end

      then_ "the board shows all 4 cleaners and their jobs across the seven days on one screen",
            context do
        assert has_element?(context.view, "[data-test='weekly-board']")

        for cleaner <- context.cleaners do
          assert has_element?(
                   context.view,
                   "[data-test='cleaner-column-#{cleaner.id}']",
                   cleaner.email
                 )
        end

        for job <- context.jobs do
          assert has_element?(context.view, "[data-test='job-#{job.id}']")
        end

        {:ok, context}
      end
    end
  end

  defp week_monday do
    today = Date.utc_today()
    Date.add(today, -(Date.day_of_week(today) - 1))
  end
end
