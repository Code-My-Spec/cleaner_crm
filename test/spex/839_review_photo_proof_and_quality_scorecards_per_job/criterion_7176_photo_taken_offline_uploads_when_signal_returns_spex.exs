defmodule CleanerCrmSpex.Story839.Criterion7176Spex do
  @moduledoc """
  Story 839 — Review photo proof and quality scorecards per job
  Criterion 7176 — Photo taken offline uploads when signal returns
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a photo captured with no signal finishes uploading once connectivity returns" do
    scenario "photo taken offline uploads when signal returns" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

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

      when_ "Ana captures the required after photo of the first task while her phone has no signal",
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
