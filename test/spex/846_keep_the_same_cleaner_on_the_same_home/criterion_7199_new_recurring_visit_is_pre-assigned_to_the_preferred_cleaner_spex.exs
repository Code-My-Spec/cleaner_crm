defmodule CleanerCrmSpex.Story846.Criterion7199Spex do
  @moduledoc """
  Story 846 — Keep the same cleaner on the same home
  Criterion 7199 — New recurring visit is pre-assigned to the preferred
  cleaner: every visit a recurring plan generates — not only the
  first — defaults to the plan's preferred cleaner without the owner
  manually assigning each one.

  Assumes `CleanerCrmWeb.ScheduleLive.PlanFormComponent` (opened from
  `/app/schedule/plans/new`, per story 833's own specs) exposes a
  `[data-test='plan-form']` whose `cleaner_id` field designates the
  plan's preferred cleaner and a `[data-test='save-plan-button']` that
  saves the plan and materializes every occurrence immediately, per
  criterion 7143.
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  spex "every generated visit in a recurring plan defaults to the preferred cleaner" do
    scenario "new recurring visit is pre-assigned to the preferred cleaner" do
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

      given_ "a cleaner \"Alex Morgan\" is set as the preferred cleaner", context do
        cleaner_path = create_cleaner(context.conn, "Alex Morgan")

        {:ok, Map.put(context, :cleaner_id, id_from_path(cleaner_path))}
      end

      when_ "the owner creates a 3-visit weekly recurring plan without assigning each visit",
            context do
        {:ok, plan_live, _html} = live(context.conn, ~p"/app/schedule/plans/new")

        plan_live
        |> form("[data-test='plan-form']",
          plan: %{
            property_id: context.property_id,
            cleaner_id: context.cleaner_id,
            recurrence: "weekly",
            start_date: Date.to_iso8601(first_visit_date()),
            occurrence_count: 3
          }
        )
        |> render_change()

        plan_live
        |> element("[data-test='save-plan-button']")
        |> render_click()

        {:ok, context}
      end

      then_ "all 3 generated visits are pre-assigned to Alex Morgan", context do
        {:ok, board_live, html} = live(context.conn, ~p"/app/schedule")

        visit_job_ids = job_ids(html)

        assert length(visit_job_ids) == 3

        for job_id <- visit_job_ids do
          assert has_element?(
                   board_live,
                   "[data-test='cleaner-column-#{context.cleaner_id}'] [data-test='job-#{job_id}']"
                 )
        end

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
