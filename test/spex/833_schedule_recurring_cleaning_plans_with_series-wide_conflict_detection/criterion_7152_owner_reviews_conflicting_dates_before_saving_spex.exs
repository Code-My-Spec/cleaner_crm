defmodule CleanerCrmSpex.Story833.Criterion7152Spex do
  @moduledoc """
  Story 833 — Schedule recurring cleaning plans with series-wide conflict detection
  Criterion 7152 — When a proposed series has conflicting occurrences, the
  owner is shown which dates conflict before the plan is saved, and can
  resolve or override them.
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  spex "the owner reviews series conflicts before a plan is saved" do
    scenario "owner reviews conflicting dates before saving" do
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

      given_ "a proposed series has conflicts on the 4th and 7th visits", context do
        create_time_off(context.conn, context.cleaner_id, visit_date(4))
        create_time_off(context.conn, context.cleaner_id, visit_date(7))

        {:ok, plan_live, _html} = live(context.conn, ~p"/schedule/plans/new")

        plan_live
        |> form("[data-test='plan-form']",
          plan: %{
            property_id: context.property_id,
            cleaner_id: context.cleaner_id,
            recurrence: "weekly",
            start_date: Date.to_iso8601(first_visit_date())
          }
        )
        |> render_change()

        {:ok, Map.put(context, :plan_live, plan_live)}
      end

      when_ "the owner reviews the plan before saving", context do
        context.plan_live
        |> form("[data-test='plan-form']", plan: %{occurrence_count: 8})
        |> render_change()

        {:ok, context}
      end

      then_ "the owner sees a list naming the 4th and 7th visits as conflicting", context do
        assert has_element?(context.plan_live, "[data-test='conflict-visit-4']")
        assert has_element?(context.plan_live, "[data-test='conflict-visit-7']")

        {:ok, context}
      end

      and_ "the owner can resolve or override them before the plan is saved", context do
        assert has_element?(context.plan_live, "[data-test='override-conflict-4']")
        assert has_element?(context.plan_live, "[data-test='override-conflict-7']")
        assert has_element?(context.plan_live, "[data-test='save-plan-button']")

        {:ok, context}
      end
    end
  end

  defp first_visit_date, do: Date.add(Date.utc_today(), 14)
  defp visit_date(n), do: Date.add(first_visit_date(), (n - 1) * 7)
  defp id_from_path(path), do: path |> String.split("/") |> List.last()

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

  defp create_cleaner(conn, name) do
    {:ok, new_live, _html} = live(conn, ~p"/schedule/cleaners/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='cleaner-form']", cleaner: %{name: name})
      |> render_submit()

    path
  end

  defp create_time_off(conn, cleaner_id, date) do
    {:ok, new_live, _html} = live(conn, ~p"/schedule/cleaners/#{cleaner_id}/time-off/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='time-off-form']",
        time_off: %{date: Date.to_iso8601(date), all_day: true}
      )
      |> render_submit()

    path
  end
end
