defmodule CleanerCrmSpex.Story832.Criterion7117Spex do
  @moduledoc """
  Story 832 — Manage clients and properties with access details
  Criterion 7117 — Deactivating a client with upcoming scheduled jobs
  hides it from active lists while retaining its history and
  properties.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "owner deactivates a client with upcoming jobs" do
    scenario "the deactivated client is hidden but its data is retained" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client with a job scheduled next week", context do
        client_path = create_client(context.conn, "Morgan Reyes")

        property_path =
          create_property(context.conn, client_path, %{service_address: "9 Birch Ln"})

        schedule_job(context.conn, property_path, next_week())

        {:ok, Map.put(context, :client_path, client_path)}
      end

      when_ "the owner deactivates the client", context do
        {:ok, show_live, _html} = live(context.conn, context.client_path)

        # The trigger button only opens the confirm dialog client-side
        # (JS.add_class — no server round-trip for LiveViewTest to click
        # through); the dialog is always in the DOM, so the spec asserts
        # the trigger exists and drives the dialog's confirm button.
        assert has_element?(show_live, "[data-test='deactivate-client-button']")

        show_live
        |> element("#deactivate-client-dialog [data-role='confirm-confirm']")
        |> render_click()

        {:ok, context}
      end

      then_ "the client is marked inactive and hidden from active lists", context do
        {:ok, _index_live, html} = live(context.conn, ~p"/app/clients")
        refute html =~ "Morgan Reyes"

        {:ok, context}
      end

      then_ "the client's history and properties are retained", context do
        {:ok, _show_live, html} = live(context.conn, context.client_path)

        assert html =~ "Morgan Reyes"
        assert html =~ "9 Birch Ln"

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

  defp schedule_job(conn, property_path, scheduled_date) do
    "/app/properties/" <> property_id = property_path

    {:ok, schedule_live, _html} = live(conn, ~p"/app/schedule")

    schedule_live
    |> element("[data-test='new-job-button']")
    |> render_click()

    schedule_live
    |> form("[data-test='job-form']",
      job: %{property_id: property_id, scheduled_date: scheduled_date}
    )
    |> render_submit()

    :ok
  end

  defp next_week do
    Date.utc_today() |> Date.add(7) |> Date.to_iso8601()
  end
end
