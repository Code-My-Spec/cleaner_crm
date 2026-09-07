defmodule CleanerCrmWeb.HealthController do
  use CleanerCrmWeb, :controller

  def show(conn, _params) do
    send_resp(conn, 200, "ok")
  end
end
