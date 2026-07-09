defmodule CleanerCrmSpex.Story842.Criterion7160Spex do
  @moduledoc """
  Story 842 — Work each job from a room-by-room checklist with photo proof
  Criterion 7160 — Out-of-scope task is not on the checklist
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  alias CleanerCrmSpex.Fixtures

  spex "an out-of-scope task never appears on a cleaner's job checklist" do
    scenario "out-of-scope task is not on the checklist" do
      given_(:logged_in_owner_with_account)

      given_ "cleaner Ana is assigned a job whose checklist reflects only what the client agreed to",
             context do
        client = Fixtures.client_fixture(context.scope)

        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{email: "ana@example.com"})

        %{job: job, checklist: checklist} =
          Fixtures.job_with_room_checklist_fixture(context.scope, client, cleaner, [
            %{room: "Kitchen", task: "Kitchen counters wiped down", required: true},
            %{room: "Bathroom", task: "Bathrooms sanitized", required: true}
          ])

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

      then_ "she sees only the tasks that were agreed to", context do
        assert has_element?(context.job_live, "[data-test='checklist-room-Kitchen']")
        assert has_element?(context.job_live, "[data-test='checklist-room-Bathroom']")

        {:ok, context}
      end

      then_ "an add-on task the client declined, such as oven interior cleaning, is not on the checklist",
            context do
        refute render(context.job_live) =~ "Inside oven cleaned"

        {:ok, context}
      end
    end
  end
end
