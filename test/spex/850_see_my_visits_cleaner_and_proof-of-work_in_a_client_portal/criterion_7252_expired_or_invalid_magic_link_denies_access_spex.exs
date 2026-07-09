defmodule CleanerCrmSpex.Story850.Criterion7252Spex do
  @moduledoc """
  Story 850 — See my visits, cleaner, and proof-of-work in a client portal
  Criterion 7252 — Expired or invalid magic link denies access:
  access is denied and the client is offered a way to request a
  fresh link.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "an expired magic-link token denies portal access" do
    scenario "expired or invalid magic link denies access" do
      given_ "a client's magic-link token has expired", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})
        client = Fixtures.client_fixture(scope, %{name: "Morgan Blake"})

        session =
          Fixtures.portal_magic_link_fixture(client, %{
            expires_at: DateTime.add(DateTime.utc_now(), -3600, :second)
          })

        {:ok, Map.merge(context, %{client: client, session: session})}
      end

      when_ "the client follows the link", context do
        access_conn = get(context.conn, ~p"/portal/access/#{context.session.token}")

        {:ok, Map.put(context, :access_conn, access_conn)}
      end

      then_ "access to the portal is denied and the client is offered a way to request a fresh link",
            context do
        html = Phoenix.ConnTest.html_response(context.access_conn, 200)
        assert html =~ ~r/expired|invalid/i
        assert html =~ ~r/request a new link|request a fresh link/i

        {:ok, context}
      end
    end
  end
end
