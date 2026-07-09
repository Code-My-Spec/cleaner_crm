defmodule CleanerCrmSpex.Story842.Criterion7159Spex do
  @moduledoc """
  Story 842 — Work each job from a room-by-room checklist with photo proof
  Criterion 7159 — Checklist opens grouped by room
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner opens her job and sees the checklist grouped by room" do
    scenario "checklist opens grouped by room" do
      given_(:logged_in_owner_with_account)

      given_ "cleaner Ana is assigned a job with tasks spanning Kitchen, Bathroom, and Living Room",
             context do
        client = Fixtures.client_fixture(context.scope)

        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{email: "ana@example.com"})

        %{job: job, checklist: checklist} =
          Fixtures.job_with_room_checklist_fixture(context.scope, client, cleaner, [
            %{room: "Kitchen", task: "Kitchen counters wiped down", required: true},
            %{room: "Kitchen", task: "Kitchen floor mopped", required: true},
            %{room: "Bathroom", task: "Bathrooms sanitized", required: true},
            %{room: "Living Room", task: "Dust living room shelves", required: false}
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
        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "the checklist is presented as separate room sections", context do
        assert has_element?(context.job_live, "[data-test='checklist-room-Kitchen']")
        assert has_element?(context.job_live, "[data-test='checklist-room-Bathroom']")
        assert has_element?(context.job_live, "[data-test='checklist-room-Living Room']")

        {:ok, context}
      end

      then_ "each task appears under its own room, not any other room", context do
        assert has_element?(
                 context.job_live,
                 "[data-test='checklist-room-Kitchen']",
                 "Kitchen counters wiped down"
               )

        assert has_element?(
                 context.job_live,
                 "[data-test='checklist-room-Kitchen']",
                 "Kitchen floor mopped"
               )

        assert has_element?(
                 context.job_live,
                 "[data-test='checklist-room-Bathroom']",
                 "Bathrooms sanitized"
               )

        assert has_element?(
                 context.job_live,
                 "[data-test='checklist-room-Living Room']",
                 "Dust living room shelves"
               )

        refute has_element?(
                 context.job_live,
                 "[data-test='checklist-room-Bathroom']",
                 "Kitchen counters wiped down"
               )

        refute has_element?(
                 context.job_live,
                 "[data-test='checklist-room-Kitchen']",
                 "Bathrooms sanitized"
               )

        {:ok, context}
      end
    end
  end
end
