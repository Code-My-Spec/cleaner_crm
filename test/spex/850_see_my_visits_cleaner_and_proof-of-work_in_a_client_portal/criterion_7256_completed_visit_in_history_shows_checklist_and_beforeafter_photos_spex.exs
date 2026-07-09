defmodule CleanerCrmSpex.Story850.Criterion7256Spex do
  @moduledoc """
  Story 850 — See my visits, cleaner, and proof-of-work in a client portal
  Criterion 7256 — Completed visit in history shows checklist and
  before/after photos as proof-of-work.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a completed visit's history entry shows its checklist and before/after photos" do
    scenario "completed visit in history shows checklist and before/after photos" do
      given_ "a client has a past visit that was completed with a finished checklist and before/after photos",
             context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})
        client = Fixtures.client_fixture(scope, %{name: "Morgan Blake"})
        job = Fixtures.job_with_proof_of_work_fixture(scope, client)
        conn = Fixtures.portal_session_fixture(client)

        {:ok, Map.merge(context, %{client: client, job: job, conn: conn})}
      end

      when_ "the client views that visit in their service history", context do
        {:ok, portal_live, html} = live(context.conn, ~p"/portal")

        {:ok, Map.merge(context, %{portal_live: portal_live, html: html})}
      end

      then_ "the checklist results and before/after photos are displayed", context do
        assert has_element?(
                 context.portal_live,
                 "[data-test='service-history'] [data-test='visit-#{context.job.id}']",
                 "Kitchen counters wiped down"
               )

        assert has_element?(
                 context.portal_live,
                 "[data-test='visit-#{context.job.id}'] [data-test='before-photo']"
               )

        assert has_element?(
                 context.portal_live,
                 "[data-test='visit-#{context.job.id}'] [data-test='after-photo']"
               )

        {:ok, context}
      end
    end
  end
end
