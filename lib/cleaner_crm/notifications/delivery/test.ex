defmodule CleanerCrm.Notifications.Delivery.Test do
  @moduledoc """
  Deterministic SMS adapter for the test environment — always
  "delivers" without touching the network. Delivery-status changes
  (delivered/undelivered) arrive the same way Twilio's do in
  production: as a webhook callback, never as a live provider call —
  see `CleanerCrm.Notifications.handle_delivery_status/1`.
  """

  @behaviour CleanerCrm.Notifications.Delivery

  @impl true
  def send_sms(phone, _body) do
    {:ok, %{provider_message_id: "sms_test_#{System.unique_integer([:positive])}_#{phone}"}}
  end
end
