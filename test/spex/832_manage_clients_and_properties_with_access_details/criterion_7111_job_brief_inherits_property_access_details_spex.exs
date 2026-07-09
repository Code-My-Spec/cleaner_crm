defmodule CleanerCrmSpex.Story832.Criterion7111Spex do
  @moduledoc """
  Story 832 — Manage clients and properties with access details
  Criterion 7111 — A job scheduled at a property inherits that
  property's access details (entry codes, parking notes, pet notes)
  into its brief.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "job brief inherits property access details" do
    scenario "scheduling a job at a property carries its access details into the brief" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a property with lockbox code \"4821\", parking note \"driveway only\", and pet note \"dog in yard\"",
             context do
        client_path = create_client(context.conn, "Devon Ashe")

        property_path =
          create_property(context.conn, client_path, %{
            service_address: "77 Maple Ave",
            lockbox_code: "4821",
            parking_notes: "driveway only",
            pet_notes: "dog in yard"
          })

        {:ok, Map.put(context, :property_path, property_path)}
      end

      when_ "a job is scheduled at that property", context do
        schedule_live = schedule_job(context.conn, context.property_path, next_week())
        {:ok, Map.put(context, :schedule_live, schedule_live)}
      end

      then_ "the job brief shows the lockbox code, parking note, and pet note from the property",
            context do
        html = render(context.schedule_live)

        assert html =~ "77 Maple Ave"
        assert html =~ "4821"
        assert html =~ "driveway only"
        assert html =~ "dog in yard"

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

    schedule_live
  end

  defp next_week do
    Date.utc_today() |> Date.add(7) |> Date.to_iso8601()
  end
end
