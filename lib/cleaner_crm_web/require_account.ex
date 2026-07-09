defmodule CleanerCrmWeb.RequireAccount do
  @moduledoc """
  LiveView `on_mount` hook for surfaces that need an active company
  (account): a freshly-registered user has none, and every scoped
  context function guards on `active_account_id`, so letting them
  reach `/app/field` or the office pages crashes with a
  `FunctionClauseError`. Funnel them to account creation instead.

  Runs after `CleanerCrmWeb.UserAuth :require_authenticated` (which
  assigns `current_scope`) and before `CleanerCrmWeb.RequireOfficeRole`
  on office routes.
  """

  use CleanerCrmWeb, :verified_routes

  def on_mount(:default, _params, _session, socket) do
    case socket.assigns.current_scope do
      %{active_account_id: nil} ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:info, "Create your company to get started.")
          |> Phoenix.LiveView.redirect(to: ~p"/app/accounts/new")

        {:halt, socket}

      _scope ->
        {:cont, socket}
    end
  end
end
