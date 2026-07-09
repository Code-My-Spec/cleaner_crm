defmodule CleanerCrmSpex.Story846.Criterion7202Spex do
  @moduledoc """
  Story 846 — Keep the same cleaner on the same home
  Criterion 7202 — Owner is warned when reassigning away from the
  preferred cleaner: reassigning a visit on the schedule board to a
  cleaner other than the plan's preferred cleaner still succeeds, but
  the owner sees a warning that the change deviates from the client's
  preferred cleaner.

  Assumes `CleanerCrmWeb.ScheduleLive.Board` (`/app/schedule`) reassigns a
  job via `[data-test='job-<id>-cleaner-select']` (`phx-change`), per
  story 834's own specs, and renders a distinct
  `[data-test='preferred-cleaner-warning']` element (separate from the
  double-booking `[data-test='schedule-conflict-warning']` of story
  834) when the newly assigned cleaner differs from the originating
  plan's preferred cleaner.
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  spex "the board warns when a visit is reassigned away from the preferred cleaner" do
    scenario "owner is warned when reassigning away from the preferred cleaner" do
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

      given_ "a recurring plan's single visit is assigned to Alex Morgan", context do
        {:ok, plan_live, _html} = live(context.conn, ~p"/app/schedule/plans/new")

        plan_live
        |> form("[data-test='plan-form']",
          plan: %{
            property_id: context.property_id,
            cleaner_id: context.alex_id,
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

      when_ "the owner reassigns that visit to Ben Carter on the board", context do
        {:ok, view, _html} = live(context.conn, ~p"/app/schedule")

        view
        |> element("[data-test='job-#{context.job_id}-cleaner-select']")
        |> render_change(%{"cleaner_id" => to_string(context.ben_id)})

        {:ok, Map.put(context, :view, view)}
      end

      then_ "the visit is reassigned to Ben Carter", context do
        assert has_element?(
                 context.view,
                 "[data-test='cleaner-column-#{context.ben_id}'] [data-test='job-#{context.job_id}']"
               )

        {:ok, context}
      end

      and_ "the owner sees a warning that this deviates from the preferred cleaner", context do
        assert has_element?(context.view, "[data-test='preferred-cleaner-warning']")

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
