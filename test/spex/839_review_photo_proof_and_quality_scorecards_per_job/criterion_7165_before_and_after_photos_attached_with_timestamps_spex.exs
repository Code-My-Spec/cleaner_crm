defmodule CleanerCrmSpex.Story839.Criterion7165Spex do
  @moduledoc """
  Story 839 — Review photo proof and quality scorecards per job
  Criterion 7165 — Before and after photos attached with timestamps
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner attaches before/after photos with timestamps to a checklist task" do
    scenario "before and after photos attached with timestamps" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        owner_conn = Fixtures.log_in_user(context.conn, user)

        {:ok,
         Map.merge(context, %{owner_conn: owner_conn, user: user, scope: scope, account: account})}
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

      when_ "Ana finishes the job, attaching a before and an after photo to the first task",
            context do
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

        Enum.each(context.checklist.items, fn item ->
          job_live
          |> element("[data-test='checklist-item-#{item.id}']")
          |> render_click()
        end)

        job_live
        |> element("[data-test='mark-complete-button']")
        |> render_click()

        {:ok, Map.merge(context, %{job_live: job_live, task: task})}
      end

      then_ "both photos are attached to the task with capture timestamps", context do
        assert has_element?(
                 context.job_live,
                 "[data-test='task-#{context.task.id}-before-photo-timestamp']"
               )

        assert has_element?(
                 context.job_live,
                 "[data-test='task-#{context.task.id}-after-photo-timestamp']"
               )

        {:ok, context}
      end

      then_ "the owner sees the timestamped before/after photos when reviewing the job",
            context do
        {:ok, review_live, _html} = live(context.owner_conn, ~p"/quality/#{context.job.id}")

        assert has_element?(review_live, "[data-test='proof-of-work-photo']")

        {:ok, context}
      end
    end
  end
end
