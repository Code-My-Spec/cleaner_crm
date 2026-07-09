defmodule CleanerCrmSpex.Story851.Criterion7227Spex do
  @moduledoc """
  Story 851 — Reschedule or cancel a visit within the policy
  Criterion 7227 — Cannot modify a completed visit

  Assumes `PortalLive.Visit` omits the reschedule form and cancel
  button entirely for a completed visit, rather than rendering them
  disabled.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a completed visit offers no reschedule or cancel controls in the portal" do
    scenario "cannot modify a completed visit" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "I have a visit that has already been completed", context do
        client = Fixtures.client_fixture(context.scope)
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)
        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok, Map.merge(context, %{client: client, job: job, portal_conn: portal_conn})}
      end

      when_ "I open that visit in the portal", context do
        {:ok, visit_live, _html} =
          live(context.portal_conn, ~p"/portal/visits/#{context.job.id}")

        {:ok, Map.put(context, :visit_live, visit_live)}
      end

      then_ "there is no way to reschedule or cancel it", context do
        refute has_element?(context.visit_live, "[data-test='reschedule-form']")
        refute has_element?(context.visit_live, "[data-test='cancel-visit-button']")

        {:ok, context}
      end
    end
  end
end
