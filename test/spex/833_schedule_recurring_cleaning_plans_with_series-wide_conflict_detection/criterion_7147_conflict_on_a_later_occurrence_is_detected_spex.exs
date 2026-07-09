defmodule CleanerCrmSpex.Story833.Criterion7147Spex do
  @moduledoc """
  Story 833 — Schedule recurring cleaning plans with series-wide conflict detection
  Criterion 7147 — Conflict detection runs across every occurrence in the
  series, not only the first visit.
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  spex "conflict detection checks every occurrence in a series" do
    scenario "conflict on a later occurrence is detected" do
      given_(:logged_in_owner_with_account)

      given_ "a client \"Jamie Rivera\" with a property exists", context do
        client_path = create_client(context.conn, "Jamie Rivera")

        property_path =
          create_property(context.conn, client_path, %{service_address: "12 Oak Lane"})

        {:ok,
         Map.merge(context, %{
           client_path: client_path,
           property_id: id_from_path(property_path)
         })}
      end

      given_ "a cleaner \"Alex Morgan\" is available for assignment", context do
        cleaner_path = create_cleaner(context.conn, "Alex Morgan")

        {:ok, Map.put(context, :cleaner_id, id_from_path(cleaner_path))}
      end

      given_ "the assigned cleaner has a time-off block on the date of the 4th weekly visit",
             context do
        create_time_off(context.conn, context.cleaner_id, visit_date(4))

        {:ok, context}
      end

      when_ "the owner creates the 8-week weekly plan", context do
        {:ok, plan_live, _html} = live(context.conn, ~p"/app/schedule/plans/new")

        plan_live
        |> form("[data-test='plan-form']",
          plan: %{
            property_id: context.property_id,
            cleaner_id: context.cleaner_id,
            recurrence: "weekly",
            start_date: Date.to_iso8601(first_visit_date()),
            occurrence_count: 8
          }
        )
        |> render_change()

        plan_live
        |> element("[data-test='save-plan-button']")
        |> render_click()

        {:ok, Map.put(context, :plan_live, plan_live)}
      end

      then_ "the system flags the 4th visit as conflicting", context do
        html = render(context.plan_live)

        assert has_element?(context.plan_live, "[data-test='conflict-visit-4']")
        assert html =~ "Visit 4"

        {:ok, context}
      end

      and_ "the first visit is not the only date checked", context do
        refute has_element?(context.plan_live, "[data-test='conflict-visit-1']")

        assert length(Regex.scan(~r/data-test="conflict-visit-\d+"/, render(context.plan_live))) ==
                 1

        {:ok, context}
      end
    end
  end

  defp first_visit_date, do: Date.add(Date.utc_today(), 14)
  defp visit_date(n), do: Date.add(first_visit_date(), (n - 1) * 7)
  defp id_from_path(path), do: path |> String.split("/") |> List.last()

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

  defp create_cleaner(conn, name) do
    {:ok, new_live, _html} = live(conn, ~p"/app/schedule/cleaners/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='cleaner-form']", cleaner: %{name: name})
      |> render_submit()

    path
  end

  defp create_time_off(conn, cleaner_id, date) do
    {:ok, new_live, _html} = live(conn, ~p"/app/schedule/cleaners/#{cleaner_id}/time-off/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='time-off-form']",
        time_off: %{date: Date.to_iso8601(date), all_day: true}
      )
      |> render_submit()

    path
  end
end
