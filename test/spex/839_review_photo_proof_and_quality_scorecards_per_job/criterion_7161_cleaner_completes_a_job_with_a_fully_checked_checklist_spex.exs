defmodule CleanerCrmSpex.Story839.Criterion7161Spex do
  @moduledoc """
  Story 839 — Review photo proof and quality scorecards per job
  Criterion 7161 — Cleaner completes a job with a fully checked checklist
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner checks off every checklist task and completes the job" do
    scenario "cleaner completes a job with a fully checked checklist" do
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

      when_ "Ana checks off every task on the checklist, including the optional one", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        Enum.each(context.checklist.items, fn item ->
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

      then_ "the job is shown as complete to Ana", context do
        assert render(context.job_live) =~ "Complete"

        {:ok, context}
      end

      then_ "the owner sees every task checked off when reviewing the job", context do
        {:ok, _review_live, html} = live(context.owner_conn, ~p"/app/quality/#{context.job.id}")

        for item <- context.checklist.items do
          assert html =~ item.task
        end

        {:ok, context}
      end
    end
  end
end
