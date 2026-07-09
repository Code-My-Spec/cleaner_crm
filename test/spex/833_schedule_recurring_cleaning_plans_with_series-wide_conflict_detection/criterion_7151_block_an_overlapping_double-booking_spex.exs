defmodule CleanerCrmSpex.Story833.Criterion7151Spex do
  @moduledoc """
  Story 833 — Schedule recurring cleaning plans with series-wide conflict detection
  Criterion 7151 — A cleaner cannot be booked for two jobs whose times overlap.
  """

  use CleanerCrmSpex.Case

  import CleanerCrmSpex.SharedGivens

  spex "a cleaner cannot be double-booked into overlapping jobs" do
    scenario "block an overlapping double-booking" do
      given_(:logged_in_owner_with_account)

      given_ "a client \"Jamie Rivera\" with a property exists", context do
        client_path = create_client(context.conn, "Jamie Rivera")

        property_path =
          create_property(context.conn, client_path, %{service_address: "12 Oak Lane"})

        {:ok,
         Map.merge(context, %{
           client_path: client_path,
           property_id: id_from_path(property_path),
           booking_date: booking_date()
         })}
      end

      given_ "a cleaner is booked for a job from 10am to 12pm", context do
        cleaner_path = create_cleaner(context.conn, "Alex Morgan")
        cleaner_id = id_from_path(cleaner_path)

        create_job(context.conn, %{
          property_id: context.property_id,
          cleaner_id: cleaner_id,
          date: Date.to_iso8601(context.booking_date),
          start_time: "10:00",
          end_time: "12:00"
        })

        {:ok, Map.put(context, :cleaner_id, cleaner_id)}
      end

      given_ "another job exists from 11am to 1pm the same day", context do
        job_path =
          create_job(context.conn, %{
            property_id: context.property_id,
            date: Date.to_iso8601(context.booking_date),
            start_time: "11:00",
            end_time: "13:00"
          })

        {:ok, Map.put(context, :second_job_id, id_from_path(job_path))}
      end

      when_ "the owner tries to assign that cleaner another job from 11am to 1pm the same day",
            context do
        {:ok, assign_live, _html} =
          live(context.conn, ~p"/schedule/jobs/#{context.second_job_id}/assign")

        html =
          assign_live
          |> form("[data-test='assignment-form']", assignment: %{cleaner_id: context.cleaner_id})
          |> render_submit()

        {:ok, Map.put(context, :assignment_html, html)}
      end

      then_ "the second assignment is rejected as an overlap conflict", context do
        assert context.assignment_html =~ "overlap"

        {:ok, context}
      end
    end
  end

  defp booking_date, do: Date.add(Date.utc_today(), 14)
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

  defp create_job(conn, attrs) do
    {:ok, new_live, _html} = live(conn, ~p"/schedule/jobs/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='job-form']", job: attrs)
      |> render_submit()

    path
  end
end
