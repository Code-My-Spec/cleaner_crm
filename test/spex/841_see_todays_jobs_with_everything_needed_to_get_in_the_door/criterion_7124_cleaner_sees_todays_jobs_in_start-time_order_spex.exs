defmodule CleanerCrmSpex.Story841.Criterion7124Spex do
  @moduledoc """
  Story 841 — See today's jobs with everything needed to get in the door
  Criterion 7124 — The day view lists only the signed-in cleaner's own
  jobs for the selected day, ordered by scheduled start time.

  Jobs are seeded directly via `Fixtures.job_fixture/3` with
  `cleaner_id`, `scheduled_date`, `start_time`, and `end_time` — the
  same sanctioned shortcut already used by story 834's criterion 7167
  (assignment is covered end-to-end by stories 833/834; this spec's
  subject is the cleaner's own day view, a downstream reader of that
  state). Jobs are created out of start-time order to prove the view
  sorts them rather than echoing insertion order.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the day view orders today's jobs by start time" do
    scenario "cleaner sees today's jobs in start-time order" do
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

      given_ "I have three jobs scheduled for today at 9:00, 12:30, and 15:00", context do
        client = Fixtures.client_fixture(context.scope)

        property_path =
          create_property(context.conn, "/app/clients/#{client.id}", %{
            service_address: "12 Oak Lane"
          })

        property_id = id_from_path(property_path)
        today = Date.utc_today()

        Fixtures.job_fixture(context.scope, client, %{
          property_id: property_id,
          cleaner_id: context.cleaner.id,
          scheduled_date: today,
          start_time: ~T[12:30:00],
          end_time: ~T[14:00:00]
        })

        Fixtures.job_fixture(context.scope, client, %{
          property_id: property_id,
          cleaner_id: context.cleaner.id,
          scheduled_date: today,
          start_time: ~T[09:00:00],
          end_time: ~T[10:30:00]
        })

        Fixtures.job_fixture(context.scope, client, %{
          property_id: property_id,
          cleaner_id: context.cleaner.id,
          scheduled_date: today,
          start_time: ~T[15:00:00],
          end_time: ~T[16:30:00]
        })

        {:ok, context}
      end

      when_ "I open the day view", context do
        {:ok, today_live, html} = live(context.cleaner_conn, ~p"/app/field")

        {:ok, Map.merge(context, %{today_live: today_live, html: html})}
      end

      then_ "I see exactly those three job cards", context do
        assert length(Regex.scan(~r/data-test="job-card"/, context.html)) == 3

        {:ok, context}
      end

      then_ "they are ordered 9:00, then 12:30, then 15:00", context do
        start_times =
          ~r/data-test="job-start-time">\s*([^<]+?)\s*</
          |> Regex.scan(context.html)
          |> Enum.map(fn [_, time] -> time end)

        assert start_times == ["9:00", "12:30", "15:00"]

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
