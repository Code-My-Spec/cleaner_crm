defmodule CleanerCrmWeb.RequireOfficeRole do
  @moduledoc """
  Restricts office-only surfaces — scheduling, timesheets (including
  the payroll CSV export), quality, invoices, clients, quotes,
  reminders, and the audit trail — to account owners and admins.

  A cleaner (or anyone with no office role on the active account) is
  redirected to `/app/field`, their own surface, with an error flash.

  ## Usage

  As a LiveView `on_mount` hook, listed after
  `CleanerCrmWeb.UserAuth`'s `:require_authenticated` in the same
  `live_session` (it relies on `current_scope.user` already being
  assigned):

      live_session :require_office_role,
        on_mount: [
          {CleanerCrmWeb.UserAuth, :require_authenticated},
          {CleanerCrmWeb.RequireOfficeRole, :default}
        ] do
        live "/app/schedule", ScheduleLive.Index, :index
        ...
      end

  As a plug, listed after `:require_authenticated_user` in the
  pipeline, for controller routes such as the timesheet CSV export:

      pipeline :require_office_role do
        plug CleanerCrmWeb.RequireOfficeRole
      end
  """

  use CleanerCrmWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias CleanerCrm.Accounts

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    if office_role?(conn.assigns.current_scope) do
      conn
    else
      conn
      |> put_flash(:error, "You don't have access to that page.")
      |> redirect(to: ~p"/app/field")
      |> halt()
    end
  end

  def on_mount(:default, _params, _session, socket) do
    scope = socket.assigns.current_scope

    if office_role?(scope) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You don't have access to that page.")
        |> Phoenix.LiveView.redirect(to: ~p"/app/field")

      {:halt, socket}
    end
  end

  defp office_role?(%{active_account_id: nil}), do: false

  defp office_role?(scope),
    do: Accounts.get_user_role(scope, scope.user.id, scope.active_account_id) in [:owner, :admin]
end
