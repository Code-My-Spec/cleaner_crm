defmodule CleanerCrmWeb.PortalController do
  @moduledoc """
  The magic-link entry point into the client portal: `GET
  /portal/access/:token` exchanges a token (mailed to the client, or
  handed out at booking) for a portal session — no password
  required.

  ## Dependencies

  - `CleanerCrm.Portal`
  """

  use CleanerCrmWeb, :controller

  alias CleanerCrm.Portal

  def access(conn, %{"token" => token}) do
    case Portal.access_portal(token) do
      {:ok, client_id} ->
        conn
        |> put_session(:portal_client_id, client_id)
        |> redirect(to: ~p"/portal")

      {:error, :invalid} ->
        render(conn, :invalid)
    end
  end
end
