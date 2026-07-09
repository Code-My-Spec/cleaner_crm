defmodule CleanerCrmSpex.Story842.Criterion7162Spex do
  @moduledoc """
  Story 842 — Work each job from a room-by-room checklist with photo proof
  Criterion 7162 — Checking tasks advances progress
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  alias CleanerCrmSpex.Fixtures

  spex "checking off a checklist task advances the cleaner's visible progress" do
    scenario "checking tasks advances progress" do
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

      when_ "Ana opens her job", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/field/jobs/#{context.job.id}")

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "her progress starts at zero of three tasks complete", context do
        assert has_element?(context.job_live, "[data-test='checklist-progress']", "0 of 3")

        {:ok, context}
      end

      when_ "Ana checks off the first task", context do
        [first | _] = context.checklist.items

        context.job_live
        |> element("[data-test='checklist-item-#{first.id}']")
        |> render_click()

        {:ok, context}
      end

      then_ "her progress advances to one of three tasks complete", context do
        assert has_element?(context.job_live, "[data-test='checklist-progress']", "1 of 3")

        {:ok, context}
      end
    end
  end
end
