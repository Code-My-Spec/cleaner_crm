defmodule CleanerCrmSpex.Story841.Criterion7136Spex do
  @moduledoc """
  Story 841 — See today's jobs with everything needed to get in the door
  Criterion 7136 — Each job card displays address, parking notes, entry
  method, pet notes, and client preferences drawn from the property
  record.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the job card shows the full get-in-the-door brief" do
    scenario "job card shows the full get-in-the-door brief" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "I am a cleaner signed in on my phone", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        cleaner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), cleaner)

        {:ok, Map.merge(context, %{cleaner: cleaner, cleaner_conn: cleaner_conn})}
      end

      given_ "my job's property has an address, parking notes, entry method, pet notes, and client preferences on file",
             context do
        client = Fixtures.client_fixture(context.scope)

        property_path =
          create_property(context.conn, "/app/clients/#{client.id}", %{
            service_address: "77 Maple Ave",
            parking_notes: "Driveway only, do not block the garage",
            entry_method: "Enter through the side gate keypad",
            pet_notes: "Friendly dog in the yard, keep gate latched",
            client_preferences: "Shoes off inside, eco-friendly products only"
          })

        Fixtures.job_fixture(context.scope, client, %{
          property_id: id_from_path(property_path),
          cleaner_id: context.cleaner.id,
          scheduled_date: Date.utc_today(),
          start_time: ~T[09:00:00],
          end_time: ~T[10:30:00]
        })

        {:ok, context}
      end

      when_ "I open the job card", context do
        {:ok, today_live, _html} = live(context.cleaner_conn, ~p"/app/field")

        {:ok, Map.put(context, :today_live, today_live)}
      end

      then_ "I see the address, parking notes, entry method, pet notes, and client preferences all on that card",
            context do
        assert has_element?(context.today_live, "[data-test='job-address']", "77 Maple Ave")

        assert has_element?(
                 context.today_live,
                 "[data-test='job-parking-notes']",
                 "Driveway only, do not block the garage"
               )

        assert has_element?(
                 context.today_live,
                 "[data-test='job-entry-method']",
                 "Enter through the side gate keypad"
               )

        assert has_element?(
                 context.today_live,
                 "[data-test='job-pet-notes']",
                 "Friendly dog in the yard, keep gate latched"
               )

        assert has_element?(
                 context.today_live,
                 "[data-test='job-client-preferences']",
                 "Shoes off inside, eco-friendly products only"
               )

        {:ok, context}
      end
    end
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

  defp id_from_path(path), do: path |> String.split("/") |> List.last()
end
