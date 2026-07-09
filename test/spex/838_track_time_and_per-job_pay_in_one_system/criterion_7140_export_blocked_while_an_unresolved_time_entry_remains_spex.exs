defmodule CleanerCrmSpex.Story838.Criterion7140Spex do
  @moduledoc """
  Story 838 — Track time and per-job pay in one system
  Criterion 7140 — Export blocked while an unresolved time entry remains

  The missing-clock-out state itself is covered end-to-end by story
  838's own "cleaner forgets to clock out" spec. This spec's subject
  is how the payroll export reacts to that unresolved entry.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "payroll export is blocked while a time entry is unresolved" do
    scenario "export blocked while an unresolved time entry remains" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        owner_conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{owner_conn: owner_conn, scope: scope, account: account})}
      end

      given_ "a cleaner is assigned to a job", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "unresolved-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            status: :scheduled
          })

        {:ok, Map.merge(context, %{cleaner: cleaner, job: job})}
      end

      given_ "the cleaner clocked in on the job but never clocked out", context do
        cleaner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), context.cleaner)

        {:ok, job_live, _html} = live(cleaner_conn, ~p"/field/jobs/#{context.job.id}")

        job_live
        |> element("[data-test='clock-in-button']")
        |> render_click()

        {:ok, context}
      end

      when_ "the owner attempts to export the pay period containing that job", context do
        {:ok, timesheet_live, html} = live(context.owner_conn, ~p"/timesheets")

        {:ok, Map.merge(context, %{timesheet_live: timesheet_live, timesheet_html: html})}
      end

      then_ "the export control is disabled with a message to resolve the open entry first",
            context do
        assert has_element?(
                 context.timesheet_live,
                 "[data-test='export-csv-button'][disabled]"
               )

        assert context.timesheet_html =~ "Resolve the unresolved time entry before exporting"

        {:ok, context}
      end

      then_ "the unresolved job is called out for the owner to fix", context do
        assert has_element?(
                 context.timesheet_live,
                 "[data-test='unresolved-entry-job-#{context.job.id}']"
               )

        {:ok, context}
      end
    end
  end
end
