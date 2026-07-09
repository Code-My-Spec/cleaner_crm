defmodule CleanerCrmSpex.Story832.Criterion7115Spex do
  @moduledoc """
  Story 832 — Manage clients and properties with access details
  Criterion 7115 — Changing a property's entry code is recorded in an
  audit trail capturing who changed it and when.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "entry code changes are audited" do
    scenario "changing the alarm code logs an audit entry" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a property with alarm code \"1234\"", context do
        client_path = create_client(context.conn, "Alex Rivera")

        property_path =
          create_property(context.conn, client_path, %{
            service_address: "12 Cedar Ct",
            alarm_code: "1234"
          })

        {:ok, Map.put(context, :property_path, property_path)}
      end

      when_ "the owner changes the alarm code to \"5678\"", context do
        "/app/properties/" <> property_id = context.property_path
        {:ok, edit_live, _html} = live(context.conn, ~p"/app/properties/#{property_id}/edit")

        {:error, {:live_redirect, %{to: _path}}} =
          edit_live
          |> form("[data-test='property-form']", property: %{alarm_code: "5678"})
          |> render_submit()

        {:ok, context}
      end

      then_ "an audit entry records the owner's identity, the timestamp, and that the alarm code was changed",
            context do
        {:ok, property_live, html} = live(context.conn, context.property_path)

        assert html =~ "Access Change History"
        assert has_element?(property_live, "[data-test='audit-entry']", context.user.email)
        assert has_element?(property_live, "[data-test='audit-entry']", "alarm code")
        assert has_element?(property_live, "[data-test='audit-entry'][data-timestamp]")

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
