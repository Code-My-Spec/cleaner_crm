defmodule CleanerCrmSpex.Story850.Criterion7251Spex do
  @moduledoc """
  Story 850 — See my visits, cleaner, and proof-of-work in a client portal
  Criterion 7251 — Client opens the portal via a valid magic link: the
  portal opens showing upcoming visits and service history, with no
  password required.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a valid magic-link token opens the client's portal" do
    scenario "client opens the portal via a valid magic link" do
      given_ "a client has been sent a magic-link token for their portal", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})
        client = Fixtures.client_fixture(scope, %{name: "Morgan Blake"})
        session = Fixtures.portal_magic_link_fixture(client)

        {:ok, Map.merge(context, %{client: client, session: session})}
      end

      when_ "the client follows the link", context do
        access_conn = get(context.conn, ~p"/portal/access/#{context.session.token}")

        {:ok, Map.put(context, :access_conn, access_conn)}
      end

      then_ "the portal opens showing their upcoming visits and service history without requiring a password",
            context do
        assert redirected_to(context.access_conn) == ~p"/portal"

        {:ok, portal_live, _html} = context.access_conn |> recycle() |> live(~p"/portal")

        assert has_element?(portal_live, "[data-test='upcoming-visits']")
        assert has_element?(portal_live, "[data-test='service-history']")

        {:ok, context}
      end
    end
  end
end
