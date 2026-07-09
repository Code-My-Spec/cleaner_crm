defmodule CleanerCrmSpex.Story850.Criterion7255Spex do
  @moduledoc """
  Story 850 — See my visits, cleaner, and proof-of-work in a client portal
  Criterion 7255 — Unassigned upcoming visit shows a placeholder: a
  visit with no cleaner assigned yet shows a clear "not yet assigned"
  state instead of a blank or broken card.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "an unassigned upcoming visit shows a not-yet-assigned placeholder" do
    scenario "unassigned upcoming visit shows a placeholder" do
      given_ "a client has an upcoming visit that has no cleaner assigned yet", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})
        client = Fixtures.client_fixture(scope, %{name: "Morgan Blake"})
        job = Fixtures.job_fixture(scope, client, %{cleaner_id: nil})
        conn = Fixtures.portal_session_fixture(client)

        {:ok, Map.merge(context, %{client: client, job: job, conn: conn})}
      end

      when_ "the client views the portal", context do
        {:ok, portal_live, html} = live(context.conn, ~p"/portal")

        {:ok, Map.merge(context, %{portal_live: portal_live, html: html})}
      end

      then_ "the visit shows a \"cleaner not yet assigned\" placeholder instead of a blank or broken card",
            context do
        assert has_element?(
                 context.portal_live,
                 "[data-test='visit-#{context.job.id}'] [data-test='cleaner-not-assigned']"
               )

        refute has_element?(
                 context.portal_live,
                 "[data-test='visit-#{context.job.id}'] [data-test='assigned-cleaner-photo']"
               )

        {:ok, context}
      end
    end
  end
end
