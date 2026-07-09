defmodule CleanerCrmSpex.Story842.Criterion7172Spex do
  @moduledoc """
  Story 842 — Work each job from a room-by-room checklist with photo proof
  Criterion 7172 — Photo taken offline uploads when signal returns
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  alias CleanerCrmSpex.Fixtures

  spex "a checklist photo captured with no signal finishes uploading once connectivity returns" do
    scenario "photo taken offline uploads when signal returns" do
      given_(:logged_in_owner_with_account)

      given_ "cleaner Ana is logged in on her assigned job with a checklist", context do
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

      when_ "Ana captures the after photo of the first task while her phone has no signal",
            context do
        [task | _] = context.checklist.items

        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        upload =
          file_input(
            job_live,
            "[data-test='task-#{task.id}-after-photo-form']",
            :after_photo,
            [
              %{
                name: "after_kitchen.jpg",
                content: String.duplicate("a", 100),
                type: "image/jpeg"
              }
            ]
          )

        render_upload(upload, "after_kitchen.jpg", 40)

        {:ok, Map.merge(context, %{job_live: job_live, task: task, upload: upload})}
      end

      then_ "the photo sits queued as a pending upload", context do
        assert has_element?(
                 context.job_live,
                 "[data-test='task-#{context.task.id}-photo-pending']"
               )

        {:ok, context}
      end

      when_ "her signal returns", context do
        render_upload(context.upload, "after_kitchen.jpg", 60)

        {:ok, context}
      end

      then_ "the photo finishes uploading and is attached to the task", context do
        refute has_element?(
                 context.job_live,
                 "[data-test='task-#{context.task.id}-photo-pending']"
               )

        assert has_element?(
                 context.job_live,
                 "[data-test='task-#{context.task.id}-after-photo']"
               )

        {:ok, context}
      end
    end
  end
end
