defmodule CleanerCrmSpex.Story832.Criterion7107Spex do
  @moduledoc """
  Story 832 — Manage clients and properties with access details
  Criterion 7107 — Adding a property under an existing client saves it
  and lists it under that client as its only owning client.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "owner adds a property to an existing client" do
    scenario "the property is saved and listed under its client" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client \"Sarah Kim\" exists", context do
        client_path = create_client(context.conn, "Sarah Kim")
        {:ok, Map.put(context, :client_path, client_path)}
      end

      when_ "the owner adds a property \"123 Oak St\" and assigns it to Sarah Kim", context do
        property_path =
          create_property(context.conn, context.client_path, %{service_address: "123 Oak St"})

        {:ok, Map.put(context, :property_path, property_path)}
      end

      then_ "the property is saved and listed under Sarah Kim", context do
        {:ok, _client_live, html} = live(context.conn, context.client_path)
        assert html =~ "123 Oak St"

        {:ok, context}
      end

      then_ "the property shows Sarah Kim as its only owning client", context do
        {:ok, property_live, html} = live(context.conn, context.property_path)

        assert has_element?(property_live, "[data-test='property-client']", "Sarah Kim")
        assert length(Regex.scan(~r/data-test="property-client"/, html)) == 1

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

  defp create_property(conn, client_path, attrs) do
    "/app/clients/" <> client_id = client_path

    {:ok, new_live, _html} = live(conn, ~p"/app/clients/#{client_id}/properties/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='property-form']", property: attrs)
      |> render_submit()

    path
  end
end
