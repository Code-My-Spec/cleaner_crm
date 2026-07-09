defmodule CleanerCrmWeb.PortalAuth do
  @moduledoc """
  Gates the client portal's LiveViews behind a magic-link session —
  no user login. Reads the client id `CleanerCrmWeb.PortalController`
  wrote to the session's `:portal_client_id` key after a valid
  `/portal/access/:token` exchange, mirroring how
  `CleanerCrmWeb.UserAuth` reads `:user_token` for staff auth.

  ## Usage

      live_session :portal,
        on_mount: [{CleanerCrmWeb.PortalAuth, :require_client}] do
        live "/portal", PortalLive.Home, :index
      end
  """

  use CleanerCrmWeb, :verified_routes

  alias CleanerCrm.Portal

  def on_mount(:require_client, _params, session, socket) do
    case session["portal_client_id"] do
      nil ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(
            :error,
            "Please use your portal link to sign in, or request a new one below."
          )
          |> Phoenix.LiveView.redirect(to: ~p"/portal/request-link")

        {:halt, socket}

      client_id ->
        {:cont,
         Phoenix.Component.assign_new(socket, :client, fn -> Portal.get_client!(client_id) end)}
    end
  end
end
