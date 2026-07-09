defmodule CleanerCrmSpex.Story839.Criterion7163Spex do
  @moduledoc """
  Story 839 — Review photo proof and quality scorecards per job
  Criterion 7163 — Cleaner tries to complete with unchecked required tasks
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner tries to finish a job while a required task is still unchecked" do
    scenario "cleaner tries to complete with unchecked required tasks" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "cleaner Ana is logged in on her assigned job with two required tasks", context do
        client = Fixtures.client_fixture(context.scope)

        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{email: "ana@example.com"})

        %{job: job, checklist: checklist} =
          Fixtures.job_with_checklist_fixture(context.scope, client, cleaner)

        conn = Fixtures.log_in_user(build_conn(), cleaner)

        {:ok,
         Map.merge(context, %{
           client: client,
           cleaner: cleaner,
           job: job,
           checklist: checklist,
           conn: conn
         })}
      end

      when_ "Ana checks off only one of the two required tasks", context do
        [first_required | _] = Enum.filter(context.checklist.items, & &1.required)

        {:ok, job_live, _html} = live(context.conn, ~p"/field/jobs/#{context.job.id}")

        job_live
        |> element("[data-test='checklist-item-#{first_required.id}']")
        |> render_click()

        {:ok, Map.put(context, :job_live, job_live)}
      end

      when_ "Ana tries to mark the job complete", context do
        html =
          context.job_live
          |> element("[data-test='mark-complete-button']")
          |> render_click()

        {:ok, Map.put(context, :html_after_attempt, html)}
      end

      then_ "the job is not marked complete", context do
        refute render(context.job_live) =~ "Complete"

        {:ok, context}
      end

      then_ "Ana is prompted to check off or mark the remaining task skipped with a reason",
            context do
        [_first_required, second_required] = Enum.filter(context.checklist.items, & &1.required)

        assert has_element?(context.job_live, "[data-test='incomplete-required-tasks-warning']")
        assert context.html_after_attempt =~ second_required.task

        assert has_element?(
                 context.job_live,
                 "[data-test='skip-task-#{second_required.id}-button']"
               )

        {:ok, context}
      end
    end
  end
end
