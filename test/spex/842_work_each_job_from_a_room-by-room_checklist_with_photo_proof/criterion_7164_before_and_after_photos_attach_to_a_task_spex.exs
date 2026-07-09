defmodule CleanerCrmSpex.Story842.Criterion7164Spex do
  @moduledoc """
  Story 842 — Work each job from a room-by-room checklist with photo proof
  Criterion 7164 — Before and after photos attach to a task
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner attaches before and after photos as proof for a checklist task" do
    scenario "before and after photos attach to a task" do
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

      when_ "Ana attaches a before photo and an after photo to the first task", context do
        [task | _] = context.checklist.items

        {:ok, job_live, _html} = live(context.conn, ~p"/field/jobs/#{context.job.id}")

        before_upload =
          file_input(
            job_live,
            "[data-test='task-#{task.id}-before-photo-form']",
            :before_photo,
            [%{name: "before_kitchen.jpg", content: "before-photo-bytes", type: "image/jpeg"}]
          )

        render_upload(before_upload, "before_kitchen.jpg")

        after_upload =
          file_input(
            job_live,
            "[data-test='task-#{task.id}-after-photo-form']",
            :after_photo,
            [%{name: "after_kitchen.jpg", content: "after-photo-bytes", type: "image/jpeg"}]
          )

        render_upload(after_upload, "after_kitchen.jpg")

        {:ok, Map.merge(context, %{job_live: job_live, task: task})}
      end

      then_ "both photos are visibly attached to that task", context do
        assert has_element?(
                 context.job_live,
                 "[data-test='task-#{context.task.id}-before-photo']"
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
