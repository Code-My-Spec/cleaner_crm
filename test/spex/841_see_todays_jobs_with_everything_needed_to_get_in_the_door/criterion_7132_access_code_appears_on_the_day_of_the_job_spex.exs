defmodule CleanerCrmSpex.Story841.Criterion7132Spex do
  @moduledoc """
  Story 841 — See today's jobs with everything needed to get in the door
  Criterion 7132 — Lockbox and alarm access codes are revealed in full
  on a job card on the job's scheduled date.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "access codes are revealed on the day of the job" do
    scenario "access code appears on the day of the job" do
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

      given_ "I have a job scheduled for today with a lockbox code and an alarm code on file",
             context do
        client = Fixtures.client_fixture(context.scope)

        property_path =
          create_property(context.conn, "/app/clients/#{client.id}", %{
            service_address: "77 Maple Ave",
            lockbox_code: "4821",
            alarm_code: "9034"
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

      when_ "I open that job card", context do
        {:ok, today_live, html} = live(context.cleaner_conn, ~p"/app/field")

        {:ok, Map.merge(context, %{today_live: today_live, html: html})}
      end

      then_ "the lockbox code and alarm code are shown in full", context do
        assert has_element?(context.today_live, "[data-test='job-lockbox-code']", "4821")
        assert has_element?(context.today_live, "[data-test='job-alarm-code']", "9034")

        refute has_element?(
                 context.today_live,
                 "[data-test='job-lockbox-code'][data-masked='true']"
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
