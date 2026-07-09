defmodule CleanerCrmSpex.Story832.Criterion7110Spex do
  @moduledoc """
  Story 832 — Manage clients and properties with access details
  Criterion 7110 — A property cannot be saved without a service
  address; a blank address is rejected with an error.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "owner tries to save a property with a blank address" do
    scenario "the property with a blank address is rejected" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "the owner is adding a property for a client", context do
        client_path = create_client(context.conn, "Priya Nair")
        "/clients/" <> client_id = client_path

        {:ok, new_live, _html} = live(context.conn, ~p"/clients/#{client_id}/properties/new")

        {:ok, Map.merge(context, %{client_path: client_path, new_live: new_live})}
      end

      when_ "the owner leaves the service address blank and tries to save", context do
        context.new_live
        |> form("[data-test='property-form']", property: %{service_address: ""})
        |> render_submit()

        {:ok, context}
      end

      then_ "the property is not saved", context do
        assert has_element?(context.new_live, "[data-test='property-form']")

        {:ok, context}
      end

      then_ "the owner sees an error that a service address is required", context do
        assert has_element?(
                 context.new_live,
                 "[data-test='service-address-error']",
                 "is required"
               )

        {:ok, context}
      end
    end
  end

  defp create_client(conn, name) do
    {:ok, new_live, _html} = live(conn, ~p"/clients/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='client-form']", client: %{name: name})
      |> render_submit()

    path
  end
end
