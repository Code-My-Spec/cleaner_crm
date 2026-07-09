defmodule CleanerCrmSpex.Story842.Criterion7169Spex do
  @moduledoc """
  Story 842 — Work each job from a room-by-room checklist with photo proof
  Criterion 7169 — Completion blocked with a required task unchecked
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  alias CleanerCrmSpex.Fixtures

  spex "a job cannot be marked complete while a required checklist task is unchecked" do
    scenario "completion blocked with a required task unchecked" do
      given_(:logged_in_owner_with_account)

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

        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

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

      then_ "Ana is shown which required task is still blocking completion", context do
        [_first_required, second_required] = Enum.filter(context.checklist.items, & &1.required)

        assert has_element?(context.job_live, "[data-test='incomplete-required-tasks-warning']")
        assert context.html_after_attempt =~ second_required.task

        {:ok, context}
      end
    end
  end
end
