defmodule CleanerCrmSpex.Story842.Criterion7166Spex do
  @moduledoc """
  Story 842 — Work each job from a room-by-room checklist with photo proof
  Criterion 7166 — Job completes when all required items are done
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  alias CleanerCrmSpex.Fixtures

  spex "a job completes once every required checklist item is done, regardless of optional items" do
    scenario "job completes when all required items are done" do
      given_(:logged_in_owner_with_account)

      given_ "cleaner Ana is logged in on her assigned job with two required tasks and one optional task",
             context do
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

      when_ "Ana checks off both required tasks but leaves the optional task unchecked",
            context do
        {:ok, job_live, _html} = live(context.conn, ~p"/field/jobs/#{context.job.id}")

        context.checklist.items
        |> Enum.filter(& &1.required)
        |> Enum.each(fn item ->
          job_live
          |> element("[data-test='checklist-item-#{item.id}']")
          |> render_click()
        end)

        {:ok, Map.put(context, :job_live, job_live)}
      end

      when_ "Ana marks the job complete", context do
        context.job_live
        |> element("[data-test='mark-complete-button']")
        |> render_click()

        {:ok, context}
      end

      then_ "the job is shown as complete despite the optional task remaining unchecked",
            context do
        assert render(context.job_live) =~ "Complete"

        {:ok, context}
      end
    end
  end
end
