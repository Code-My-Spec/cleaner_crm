defmodule CleanerCrmSpex.Story846.Criterion7206Spex do
  @moduledoc """
  Story 846 — Keep the same cleaner on the same home
  Criterion 7206 — No warning when the plan has no preferred cleaner:
  a recurring plan can be saved without designating a preferred
  cleaner, and assigning any cleaner to that plan's visits never
  triggers the preferred-cleaner warning, since there is no preference
  to deviate from.

  Assumes `CleanerCrmWeb.ScheduleLive.PlanFormComponent`
  (`/app/schedule/plans/new`) allows saving a plan with the `cleaner_id`
  field left blank, and `CleanerCrmWeb.ScheduleLive.Board` (`/app/schedule`)
  assigns a cleaner to a visit via
  `[data-test='job-<id>-cleaner-select']` (`phx-change`), per story
  834's own specs, rendering the distinct
  `[data-test='preferred-cleaner-warning']` only when the assignment
  deviates from an actual preferred cleaner on the originating plan.
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  spex "no preferred-cleaner warning appears for a plan without a preference" do
    scenario "no warning when the plan has no preferred cleaner" do
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

      given_ "Ben Carter is available for assignment", context do
        ben_id = create_cleaner(context.conn, "Ben Carter") |> id_from_path()

        {:ok, Map.put(context, :ben_id, ben_id)}
      end

      given_ "a recurring plan is created for the property with no preferred cleaner set",
             context do
        {:ok, plan_live, _html} = live(context.conn, ~p"/app/schedule/plans/new")

        plan_live
        |> form("[data-test='plan-form']",
          plan: %{
            property_id: context.property_id,
            recurrence: "weekly",
            start_date: Date.to_iso8601(first_visit_date()),
            occurrence_count: 1
          }
        )
        |> render_change()

        plan_live
        |> element("[data-test='save-plan-button']")
        |> render_click()

        {:ok, _board_live, html} = live(context.conn, ~p"/app/schedule")
        [job_id] = job_ids(html)

        {:ok, Map.put(context, :job_id, job_id)}
      end

      when_ "the owner assigns Ben Carter to that visit on the board", context do
        {:ok, view, _html} = live(context.conn, ~p"/app/schedule")

        view
        |> element("[data-test='job-#{context.job_id}-cleaner-select']")
        |> render_change(%{"cleaner_id" => to_string(context.ben_id)})

        {:ok, Map.put(context, :view, view)}
      end

      then_ "the visit is assigned to Ben Carter", context do
        assert has_element?(
                 context.view,
                 "[data-test='cleaner-column-#{context.ben_id}'] [data-test='job-#{context.job_id}']"
               )

        {:ok, context}
      end

      and_ "no preferred-cleaner warning is shown", context do
        refute has_element?(context.view, "[data-test='preferred-cleaner-warning']")

        {:ok, context}
      end
    end
  end

  defp first_visit_date, do: Date.add(Date.utc_today(), 14)
  defp id_from_path(path), do: path |> String.split("/") |> List.last()

  defp job_ids(html) do
    ~r/data-test="job-([0-9a-f-]+)"/
    |> Regex.scan(html)
    |> Enum.map(fn [_, id] -> id end)
    |> Enum.uniq()
  end

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
end
