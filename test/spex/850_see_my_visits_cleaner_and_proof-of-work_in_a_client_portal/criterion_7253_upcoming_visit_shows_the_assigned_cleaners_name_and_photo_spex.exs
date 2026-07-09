defmodule CleanerCrmSpex.Story850.Criterion7253Spex do
  @moduledoc """
  Story 850 — See my visits, cleaner, and proof-of-work in a client portal
  Criterion 7253 — Upcoming visit shows the assigned cleaner's name
  and photo alongside the date/time.

  The magic-link exchange itself is covered end-to-end by this
  story's own criterion 7251 spec, so the portal session is seeded
  directly via `CleanerCrmSpex.Fixtures.portal_session_fixture/1`.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "an upcoming visit shows its assigned cleaner's name and photo" do
    scenario "upcoming visit shows the assigned cleaner's name and photo" do
      given_ "a client has an upcoming visit with a cleaner assigned", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})
        cleaner = Fixtures.cleaner_fixture(scope, account, %{name: "Jamie Rivera"})
        client = Fixtures.client_fixture(scope, %{name: "Morgan Blake"})
        job = Fixtures.job_fixture(scope, client, %{cleaner_id: cleaner.id})
        conn = Fixtures.portal_session_fixture(client)

        {:ok, Map.merge(context, %{cleaner: cleaner, client: client, job: job, conn: conn})}
      end

      when_ "the client views the portal", context do
        {:ok, portal_live, html} = live(context.conn, ~p"/portal")

        {:ok, Map.merge(context, %{portal_live: portal_live, html: html})}
      end

      then_ "the visit shows the date/time along with the cleaner's name and photo", context do
        assert has_element?(
                 context.portal_live,
                 "[data-test='visit-#{context.job.id}']",
                 context.cleaner.name
               )

        assert has_element?(
                 context.portal_live,
                 "[data-test='visit-#{context.job.id}'] [data-test='assigned-cleaner-photo']"
               )

        {:ok, context}
      end
    end
  end
end
