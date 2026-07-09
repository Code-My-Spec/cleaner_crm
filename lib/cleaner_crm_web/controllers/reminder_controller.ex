defmodule CleanerCrmWeb.ReminderController do
  @moduledoc """
  Public confirm/reschedule endpoints clients reach from reminder
  messages — reached by the opaque token in the link, no
  authentication.
  """

  use CleanerCrmWeb, :controller

  alias CleanerCrm.Notifications

  def confirm(conn, %{"token" => token}) do
    case Notifications.confirm_reminder(token) do
      {:ok, _notification} -> render(conn, :confirm)
      {:error, :not_found} -> conn |> put_status(:not_found) |> render(:not_found)
    end
  end

  def reschedule(conn, %{"token" => token}) do
    case Notifications.request_reschedule(token) do
      {:ok, _notification} -> render(conn, :reschedule)
      {:error, :not_found} -> conn |> put_status(:not_found) |> render(:not_found)
    end
  end
end
