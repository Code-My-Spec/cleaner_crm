defmodule CleanerCrmSpex.Story832.Criterion7113Spex do
  @moduledoc """
  Story 832 — Manage clients and properties with access details
  Criterion 7113 — Updating a property's lockbox code propagates to
  the brief of its already-scheduled future jobs.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "updated entry code propagates to future jobs" do
    scenario "changing the lockbox code updates the upcoming job's brief" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a property with an upcoming job and lockbox code \"4821\"", context do
        client_path = create_client(context.conn, "Jordan Lee")

        property_path =
          create_property(context.conn, client_path, %{
            service_address: "45 Elm St",
            lockbox_code: "4821"
          })

        schedule_job(context.conn, property_path, next_week())

        {:ok, Map.put(context, :property_path, property_path)}
      end

      when_ "the owner changes the property's lockbox code to \"9077\"", context do
        "/properties/" <> property_id = context.property_path
        {:ok, edit_live, _html} = live(context.conn, ~p"/properties/#{property_id}/edit")

        {:error, {:live_redirect, %{to: _path}}} =
          edit_live
          |> form("[data-test='property-form']", property: %{lockbox_code: "9077"})
          |> render_submit()

        {:ok, context}
      end

      then_ "the upcoming job's brief shows lockbox code \"9077\"", context do
        {:ok, _schedule_live, html} = live(context.conn, ~p"/schedule")

        assert html =~ "45 Elm St"
        assert html =~ "9077"
        refute html =~ "4821"

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

  defp create_property(conn, client_path, attrs) do
    "/clients/" <> client_id = client_path

    {:ok, new_live, _html} = live(conn, ~p"/clients/#{client_id}/properties/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='property-form']", property: attrs)
      |> render_submit()

    path
  end

  defp schedule_job(conn, property_path, scheduled_date) do
    "/properties/" <> property_id = property_path

    {:ok, schedule_live, _html} = live(conn, ~p"/schedule")

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
