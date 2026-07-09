defmodule CleanerCrmSpex.Story833.Criterion7150Spex do
  @moduledoc """
  Story 833 — Schedule recurring cleaning plans with series-wide conflict detection
  Criterion 7150 — A job cannot be assigned to a cleaner during one of that
  cleaner's availability (time-off) blocks.
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  spex "assignment is blocked during a cleaner's time-off block" do
    scenario "block assignment during a time-off block" do
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

      given_ "a cleaner has an all-day time-off block on Friday", context do
        cleaner_path = create_cleaner(context.conn, "Alex Morgan")
        cleaner_id = id_from_path(cleaner_path)
        friday = next_friday()

        create_time_off(context.conn, cleaner_id, friday)

        {:ok, Map.merge(context, %{cleaner_id: cleaner_id, friday: friday})}
      end

      given_ "a Friday job exists unassigned for the property", context do
        job_path =
          create_job(context.conn, %{
            property_id: context.property_id,
            date: Date.to_iso8601(context.friday),
            start_time: "10:00",
            end_time: "12:00"
          })

        {:ok, Map.put(context, :job_id, id_from_path(job_path))}
      end

      when_ "the owner tries to assign that cleaner a Friday job", context do
        {:ok, assign_live, _html} =
          live(context.conn, ~p"/schedule/jobs/#{context.job_id}/assign")

        html =
          assign_live
          |> form("[data-test='assignment-form']", assignment: %{cleaner_id: context.cleaner_id})
          |> render_submit()

        {:ok, Map.put(context, :assignment_html, html)}
      end

      then_ "the assignment is rejected as a conflict", context do
        assert context.assignment_html =~ "conflict"

        {:ok, context}
      end

      and_ "the owner is told the cleaner is unavailable that day", context do
        assert context.assignment_html =~ "unavailable"

        {:ok, context}
      end
    end
  end

  defp id_from_path(path), do: path |> String.split("/") |> List.last()

  defp next_friday do
    today = Date.utc_today()
    offset = Integer.mod(5 - Date.day_of_week(today) - 1, 7) + 1
    Date.add(today, offset + 7)
  end

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

  defp create_job(conn, attrs) do
    {:ok, new_live, _html} = live(conn, ~p"/schedule/jobs/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='job-form']", job: attrs)
      |> render_submit()

    path
  end
end
