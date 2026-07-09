defmodule CleanerCrmWeb.TimesheetExportController do
  use CleanerCrmWeb, :controller

  alias CleanerCrm.TimeTracking

  def show(conn, %{"start_date" => start_date, "end_date" => end_date} = params) do
    with {:ok, start_d} <- Date.from_iso8601(start_date),
         {:ok, end_d} <- Date.from_iso8601(end_date) do
      export(conn, start_date, end_date, {start_d, end_d})
    else
      {:error, _} -> show(conn, Map.drop(params, ["start_date", "end_date"]))
    end
  end

  # Missing or malformed date params (only reachable by hand-built URLs —
  # the Export button always supplies both) get a redirect, not a crash.
  def show(conn, _params) do
    conn
    |> put_flash(:error, "Choose a pay period to export")
    |> redirect(to: ~p"/app/timesheets")
  end

  defp export(conn, start_date, end_date, period) do
    case TimeTracking.export_pay_period_csv(conn.assigns.current_scope, period) do
      {:ok, csv} ->
        conn
        |> put_resp_content_type("text/csv")
        |> put_resp_header(
          "content-disposition",
          ~s(attachment; filename="payroll-#{start_date}-#{end_date}.csv")
        )
        |> send_resp(200, csv)

      {:error, :unresolved_entries} ->
        conn
        |> put_flash(:error, "Resolve the unresolved time entry before exporting")
        |> redirect(to: ~p"/app/timesheets")
    end
  end
end
