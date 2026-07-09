defmodule CleanerCrmSpex.Story833.Criterion7149Spex do
  @moduledoc """
  Story 833 — Schedule recurring cleaning plans with series-wide conflict detection
  Criterion 7149 — A job can be assigned to a cleaner when the job's time
  does not fall inside one of that cleaner's availability blocks.
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  spex "a cleaner can be assigned within their available hours" do
    scenario "assign a cleaner within their available hours" do
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

      given_ "a cleaner is available Tuesday mornings", context do
        cleaner_path = create_cleaner(context.conn, "Alex Morgan")

        {:ok, Map.put(context, :cleaner_id, id_from_path(cleaner_path))}
      end

      given_ "a Tuesday 9am job exists unassigned for the property", context do
        job_path =
          create_job(context.conn, %{
            property_id: context.property_id,
            date: Date.to_iso8601(next_tuesday()),
            start_time: "09:00",
            end_time: "11:00"
          })

        {:ok, Map.put(context, :job_id, id_from_path(job_path))}
      end

      when_ "the owner assigns that cleaner a Tuesday 9am job", context do
        {:ok, assign_live, _html} =
          live(context.conn, ~p"/app/schedule/jobs/#{context.job_id}/assign")

        assign_live
        |> form("[data-test='assignment-form']", assignment: %{cleaner_id: context.cleaner_id})
        |> render_submit()

        {:ok, context}
      end

      then_ "the job is assigned without warning", context do
        {:ok, job_live, html} = live(context.conn, ~p"/app/schedule/jobs/#{context.job_id}")

        assert has_element?(job_live, "[data-test='job-cleaner']", "Alex Morgan")
        refute html =~ "conflict"

        {:ok, context}
      end
    end
  end

  defp id_from_path(path), do: path |> String.split("/") |> List.last()

  defp next_tuesday do
    today = Date.utc_today()
    offset = Integer.mod(2 - Date.day_of_week(today) - 1, 7) + 1
    Date.add(today, offset + 7)
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

  defp create_job(conn, attrs) do
    {:ok, new_live, _html} = live(conn, ~p"/app/schedule/jobs/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='job-form']", job: attrs)
      |> render_submit()

    path
  end
end
