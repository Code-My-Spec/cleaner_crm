defmodule CleanerCrmSpex.Story833.Criterion7143Spex do
  @moduledoc """
  Story 833 — Schedule recurring cleaning plans with series-wide conflict detection
  Criterion 7143 — A recurring plan generates a job for every occurrence in
  its series (weekly, biweekly, or monthly), not just the first.
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  spex "a recurring plan generates the full series of jobs" do
    scenario "weekly plan generates the full series" do
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

      given_ "the owner creates a weekly cleaning plan for a property running for 8 weeks",
             context do
        {:ok, plan_live, _html} = live(context.conn, ~p"/schedule/plans/new")

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

        {:ok, Map.put(context, :plan_live, plan_live)}
      end

      when_ "the plan is saved", context do
        context.plan_live
        |> element("[data-test='save-plan-button']")
        |> render_click()

        {:ok, context}
      end

      then_ "8 jobs are created, one on each scheduled date", context do
        {:ok, _board_live, html} = live(context.conn, ~p"/schedule")

        assert html =~ "8 jobs scheduled"
        assert length(Regex.scan(~r/data-test="job-card"/, html)) == 8

        {:ok, context}
      end
    end
  end

  defp first_visit_date, do: Date.add(Date.utc_today(), 14)
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
end
