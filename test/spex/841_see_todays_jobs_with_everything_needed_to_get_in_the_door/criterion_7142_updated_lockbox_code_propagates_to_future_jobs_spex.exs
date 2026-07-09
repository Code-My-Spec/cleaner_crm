defmodule CleanerCrmSpex.Story841.Criterion7142Spex do
  @moduledoc """
  Story 841 — See today's jobs with everything needed to get in the door
  Criterion 7142 — When a property's access details change, every
  future job for that property reflects the update with no manual
  re-entry per job. The edit is driven through the real property edit
  form (ClientLive's property surface); the propagation is observed
  purely from the cleaner's day view.

  Reconciled with criterion 7133 (codes stay masked before the job
  date): propagation is proven by a day-of job revealing the NEW code,
  while future jobs never expose the old code (or any code) early.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "an updated lockbox code propagates to future jobs" do
    scenario "updated lockbox code propagates to future jobs" do
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

      given_ "a property has recurring jobs assigned to me next week", context do
        client = Fixtures.client_fixture(context.scope)

        property_path =
          create_property(context.conn, "/clients/#{client.id}", %{
            service_address: "45 Elm St",
            lockbox_code: "4821"
          })

        property_id = id_from_path(property_path)
        today = Date.utc_today()
        next_monday = Date.add(Date.utc_today(), 7)
        next_thursday = Date.add(Date.utc_today(), 10)

        Fixtures.job_fixture(context.scope, client, %{
          property_id: property_id,
          cleaner_id: context.cleaner.id,
          scheduled_date: today,
          start_time: ~T[07:00:00],
          end_time: ~T[08:30:00]
        })

        Fixtures.job_fixture(context.scope, client, %{
          property_id: property_id,
          cleaner_id: context.cleaner.id,
          scheduled_date: next_monday,
          start_time: ~T[09:00:00],
          end_time: ~T[10:30:00]
        })

        Fixtures.job_fixture(context.scope, client, %{
          property_id: property_id,
          cleaner_id: context.cleaner.id,
          scheduled_date: next_thursday,
          start_time: ~T[13:00:00],
          end_time: ~T[14:30:00]
        })

        {:ok,
         Map.merge(context, %{
           property_id: property_id,
           today: today,
           next_monday: next_monday,
           next_thursday: next_thursday
         })}
      end

      when_ "the office updates that property's lockbox code", context do
        {:ok, edit_live, _html} = live(context.conn, ~p"/properties/#{context.property_id}/edit")

        {:error, {:live_redirect, %{to: _path}}} =
          edit_live
          |> form("[data-test='property-form']", property: %{lockbox_code: "9077"})
          |> render_submit()

        {:ok, context}
      end

      then_ "today's job reveals the new code and future jobs carry it forward without exposing any code early",
            context do
        {:ok, today_live, today_html} = live(context.cleaner_conn, ~p"/field")

        {:ok, _monday_live, monday_html} =
          live(context.cleaner_conn, ~p"/field?date=#{context.next_monday}")

        {:ok, _thursday_live, thursday_html} =
          live(context.cleaner_conn, ~p"/field?date=#{context.next_thursday}")

        assert has_element?(today_live, "[data-test='job-lockbox-code']", "9077")
        refute today_html =~ "4821"
        refute monday_html =~ "4821"
        refute monday_html =~ "9077"
        refute thursday_html =~ "4821"
        refute thursday_html =~ "9077"

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
