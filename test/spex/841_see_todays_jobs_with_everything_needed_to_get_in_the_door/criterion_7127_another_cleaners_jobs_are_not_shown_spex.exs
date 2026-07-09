defmodule CleanerCrmSpex.Story841.Criterion7127Spex do
  @moduledoc """
  Story 841 — See today's jobs with everything needed to get in the door
  Criterion 7127 — The day view lists only the signed-in cleaner's own
  jobs; a coworker's job scheduled for the same day is excluded.

  The coworker's job is seeded directly via `Fixtures.job_fixture/3`
  with `cleaner_id` set to the coworker — a sanctioned shortcut per
  criterion 7124's spec, since assignment itself is covered by stories
  833/834 and this spec's subject is what a *different* cleaner sees.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the day view excludes a coworker's jobs" do
    scenario "another cleaner's jobs are not shown" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "I am a cleaner signed in on my phone", context do
        me =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "me-#{System.unique_integer([:positive])}@example.com"
          })

        cleaner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), me)

        {:ok, Map.merge(context, %{me: me, cleaner_conn: cleaner_conn})}
      end

      given_ "a coworker has a job scheduled for today that is not assigned to me", context do
        coworker =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "coworker-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope)

        property_path =
          create_property(context.conn, "/clients/#{client.id}", %{
            service_address: "88 Coworker Ct"
          })

        Fixtures.job_fixture(context.scope, client, %{
          property_id: id_from_path(property_path),
          cleaner_id: coworker.id,
          scheduled_date: Date.utc_today(),
          start_time: ~T[10:00:00],
          end_time: ~T[11:30:00]
        })

        {:ok, context}
      end

      when_ "I open the day view", context do
        {:ok, today_live, html} = live(context.cleaner_conn, ~p"/field")

        {:ok, Map.merge(context, %{today_live: today_live, html: html})}
      end

      then_ "the coworker's job does not appear on my list", context do
        assert has_element?(context.today_live, "[data-test='empty-day-state']")
        refute context.html =~ "88 Coworker Ct"

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
