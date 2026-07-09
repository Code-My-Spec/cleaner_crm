defmodule CleanerCrmSpex.Story832.Criterion7118Spex do
  @moduledoc """
  Story 832 — Manage clients and properties with access details
  Criterion 7118 — A client with upcoming scheduled jobs cannot be
  permanently deleted; the owner is directed to deactivate instead.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "owner attempts to hard-delete a client with upcoming jobs" do
    scenario "the hard delete is blocked" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client with a job scheduled next week", context do
        client_path = create_client(context.conn, "Taylor Brooks")

        property_path =
          create_property(context.conn, client_path, %{service_address: "3 Willow Way"})

        schedule_job(context.conn, property_path, next_week())

        {:ok, Map.put(context, :client_path, client_path)}
      end

      when_ "the owner attempts to permanently delete the client", context do
        {:ok, show_live, _html} = live(context.conn, context.client_path)

        # The trigger button only opens the confirm dialog client-side
        # (JS.add_class — no server round-trip for LiveViewTest to click
        # through); the dialog is always in the DOM, so the spec asserts
        # the trigger exists and drives the dialog's confirm button.
        assert has_element?(show_live, "[data-test='delete-client-button']")

        html =
          show_live
          |> element("#delete-client-dialog [data-role='confirm-confirm']")
          |> render_click()

        {:ok, Map.put(context, :delete_result_html, html)}
      end

      then_ "the deletion is blocked", context do
        {:ok, _index_live, html} = live(context.conn, ~p"/app/clients")
        assert html =~ "Taylor Brooks"

        {:ok, context}
      end

      then_ "the owner is told to deactivate the client or first remove its upcoming jobs",
            context do
        assert context.delete_result_html =~ "deactivate"
        assert context.delete_result_html =~ "upcoming job"

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
