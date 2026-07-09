defmodule CleanerCrmSpex.Story841.Criterion7139Spex do
  @moduledoc """
  Story 841 — See today's jobs with everything needed to get in the door
  Criterion 7139 — A missing optional property detail renders an
  explicit placeholder on the job card instead of an error or a blank
  section.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a missing optional detail shows a clear placeholder" do
    scenario "missing optional detail shows a clear placeholder" do
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

      given_ "my job's property has no parking notes recorded", context do
        client = Fixtures.client_fixture(context.scope)

        property_path =
          create_property(context.conn, "/clients/#{client.id}", %{
            service_address: "22 Birch Rd"
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
        {:ok, today_live, html} = live(context.cleaner_conn, ~p"/field")

        {:ok, Map.merge(context, %{today_live: today_live, html: html})}
      end

      then_ "the parking section shows an explicit \"No parking notes\" placeholder", context do
        assert has_element?(
                 context.today_live,
                 "[data-test='job-parking-notes']",
                 "No parking notes"
               )

        {:ok, context}
      end

      then_ "the card does not error or leave the section blank", context do
        assert has_element?(context.today_live, "[data-test='job-address']", "22 Birch Rd")
        refute context.html =~ "exception"

        {:ok, context}
      end
    end
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

  defp id_from_path(path), do: path |> String.split("/") |> List.last()
end
