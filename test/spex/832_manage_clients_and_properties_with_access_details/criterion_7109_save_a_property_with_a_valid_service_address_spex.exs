defmodule CleanerCrmSpex.Story832.Criterion7109Spex do
  @moduledoc """
  Story 832 — Manage clients and properties with access details
  Criterion 7109 — A property with a valid, non-blank service address
  saves successfully.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "owner saves a property with a valid service address" do
    scenario "the property with an address is saved" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "the owner is adding a property for a client", context do
        client_path = create_client(context.conn, "Priya Nair")
        "/app/clients/" <> client_id = client_path

        {:ok, new_live, _html} = live(context.conn, ~p"/app/clients/#{client_id}/properties/new")

        {:ok, Map.merge(context, %{client_path: client_path, new_live: new_live})}
      end

      when_ "the owner enters the service address \"123 Oak St, Austin, TX\" and saves",
            context do
        {:error, {:live_redirect, %{to: path}}} =
          context.new_live
          |> form("[data-test='property-form']",
            property: %{service_address: "123 Oak St, Austin, TX"}
          )
          |> render_submit()

        {:ok, Map.put(context, :property_path, path)}
      end

      then_ "the property is saved with that address", context do
        {:ok, _property_live, html} = live(context.conn, context.property_path)
        assert html =~ "123 Oak St, Austin, TX"

        {:ok, context}
      end
    end
  end

  defp create_client(conn, name) do
    {:ok, new_live, _html} = live(conn, ~p"/app/clients/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='client-form']", client: %{name: name})
      |> render_submit()

    path
  end
end
