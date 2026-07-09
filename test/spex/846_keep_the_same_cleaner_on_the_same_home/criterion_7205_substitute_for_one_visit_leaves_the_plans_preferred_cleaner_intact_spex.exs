defmodule CleanerCrmSpex.Story846.Criterion7205Spex do
  @moduledoc """
  Story 846 — Keep the same cleaner on the same home
  Criterion 7205 — Substitute for one visit leaves the plan's preferred
  cleaner intact: reassigning a single visit to a substitute cleaner is
  scoped to that one visit only — it does not change the plan's
  preferred cleaner, so the plan's other visits stay with the
  originally preferred cleaner.

  Assumes `CleanerCrmWeb.ScheduleLive.Board` (`/app/schedule`) reassigns a
  job via `[data-test='job-<id>-cleaner-select']` (`phx-change`), per
  story 834's own specs, and that reassigning one job does not alter
  the cleaner already assigned to the plan's other materialized jobs.
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  spex "substituting one visit does not change the plan's preferred cleaner" do
    scenario "substitute for one visit leaves the plan's preferred cleaner intact" do
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

      given_ "Alex Morgan is the preferred cleaner and Ben Carter is also available", context do
        alex_id = create_cleaner(context.conn, "Alex Morgan") |> id_from_path()
        ben_id = create_cleaner(context.conn, "Ben Carter") |> id_from_path()

        {:ok, Map.merge(context, %{alex_id: alex_id, ben_id: ben_id})}
      end

      given_ "a recurring plan generates 2 weekly visits assigned to Alex Morgan", context do
        {:ok, plan_live, _html} = live(context.conn, ~p"/app/schedule/plans/new")

        plan_live
        |> form("[data-test='plan-form']",
          plan: %{
            property_id: context.property_id,
            cleaner_id: context.alex_id,
            recurrence: "weekly",
            start_date: Date.to_iso8601(first_visit_date()),
            occurrence_count: 2
          }
        )
        |> render_change()

        plan_live
        |> element("[data-test='save-plan-button']")
        |> render_click()

        {:ok, _board_live, html} = live(context.conn, ~p"/app/schedule")
        [substitute_job_id, other_job_id] = job_ids(html)

        {:ok,
         Map.merge(context, %{substitute_job_id: substitute_job_id, other_job_id: other_job_id})}
      end

      when_ "the owner substitutes Ben Carter for just the first visit", context do
        {:ok, view, _html} = live(context.conn, ~p"/app/schedule")

        view
        |> element("[data-test='job-#{context.substitute_job_id}-cleaner-select']")
        |> render_change(%{"cleaner_id" => to_string(context.ben_id)})

        {:ok, Map.put(context, :view, view)}
      end

      then_ "the substituted visit is now assigned to Ben Carter", context do
        assert has_element?(
                 context.view,
                 "[data-test='cleaner-column-#{context.ben_id}'] [data-test='job-#{context.substitute_job_id}']"
               )

        {:ok, context}
      end

      and_ "the plan's other visit remains with the preferred cleaner, Alex Morgan", context do
        assert has_element?(
                 context.view,
                 "[data-test='cleaner-column-#{context.alex_id}'] [data-test='job-#{context.other_job_id}']"
               )

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
