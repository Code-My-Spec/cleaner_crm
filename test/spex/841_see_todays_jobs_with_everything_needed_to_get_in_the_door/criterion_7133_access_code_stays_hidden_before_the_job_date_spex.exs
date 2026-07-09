defmodule CleanerCrmSpex.Story841.Criterion7133Spex do
  @moduledoc """
  Story 841 — See today's jobs with everything needed to get in the door
  Criterion 7133 — A lockbox code stays masked on a job card until the
  job's scheduled date arrives. The day view accepts a `date` query
  param so the cleaner can look ahead at an upcoming day.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "access codes stay hidden before the job date" do
    scenario "access code stays hidden before the job date" do
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

      given_ "I have a job scheduled for tomorrow with a lockbox code on file", context do
        client = Fixtures.client_fixture(context.scope)

        property_path =
          create_property(context.conn, "/app/clients/#{client.id}", %{
            service_address: "45 Elm St",
            lockbox_code: "9077"
          })

        tomorrow = Date.add(Date.utc_today(), 1)

        Fixtures.job_fixture(context.scope, client, %{
          property_id: id_from_path(property_path),
          cleaner_id: context.cleaner.id,
          scheduled_date: tomorrow,
          start_time: ~T[09:00:00],
          end_time: ~T[10:30:00]
        })

        {:ok, Map.put(context, :tomorrow, tomorrow)}
      end

      when_ "I view that upcoming job before its scheduled date", context do
        {:ok, today_live, html} =
          live(context.cleaner_conn, ~p"/app/field?date=#{context.tomorrow}")

        {:ok, Map.merge(context, %{today_live: today_live, html: html})}
      end

      then_ "the lockbox code is masked", context do
        assert has_element?(
                 context.today_live,
                 "[data-test='job-lockbox-code'][data-masked='true']"
               )

        refute context.html =~ "9077"

        {:ok, context}
      end

      then_ "the card indicates the code unlocks on the day of the job", context do
        assert has_element?(context.today_live, "[data-test='lockbox-unlock-notice']")

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
