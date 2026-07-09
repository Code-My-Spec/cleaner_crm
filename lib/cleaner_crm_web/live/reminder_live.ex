defmodule CleanerCrmWeb.ReminderLive do
  @moduledoc """
  Office configuration of reminder timing and a delivery log showing
  every send and its status — including failed sends the office needs
  to follow up on.

  Route: `/reminders`.
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Notifications

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Reminders
        <:subtitle>Timing and delivery log</:subtitle>
      </.header>

      <.form
        for={@settings_form}
        id="reminder-settings-form"
        data-test="reminder-settings-form"
        phx-submit="save_settings"
      >
        <.input
          field={@settings_form[:lead_time_hours]}
          type="number"
          label="Send reminders this many hours before the appointment"
        />
        <.button type="submit" phx-disable-with="Saving...">Save</.button>
      </.form>

      <div class="mt-8">
        <.header>Delivery log</.header>

        <table data-test="delivery-log" class="table">
          <tbody>
            <tr :for={notification <- @notifications} data-test={"notification-#{notification.id}"}>
              <td>{contact(notification)}</td>
              <td>{channel_label(notification.channel)}</td>
              <td>{to_string(notification.status)}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    {:ok,
     socket
     |> assign(:settings_form, settings_form(scope))
     |> assign(:notifications, Notifications.list_notifications(scope))}
  end

  @impl true
  def handle_event("save_settings", %{"settings" => params}, socket) do
    scope = socket.assigns.current_scope

    case Notifications.update_reminder_settings(scope, params) do
      {:ok, _settings} ->
        {:noreply, assign(socket, :settings_form, settings_form(scope))}

      {:error, changeset} ->
        {:noreply, assign(socket, :settings_form, to_form(changeset, as: :settings))}
    end
  end

  defp settings_form(scope) do
    scope |> Notifications.change_reminder_settings() |> to_form(as: :settings)
  end

  defp contact(%{client: %CleanerCrm.Clients.Client{} = client}) do
    [client.phone, client.email] |> Enum.reject(&is_nil/1) |> Enum.join(" / ")
  end

  defp contact(_notification), do: ""

  defp channel_label(:sms), do: "SMS"
  defp channel_label(:email), do: "Email"
  defp channel_label(:push), do: "Push"
end
