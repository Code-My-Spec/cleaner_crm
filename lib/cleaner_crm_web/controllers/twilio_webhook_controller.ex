defmodule CleanerCrmWeb.TwilioWebhookController do
  @moduledoc """
  Twilio's delivery-status callback for outbound SMS reminders and
  cleaner alerts. Always acks 200 so Twilio doesn't retry, regardless
  of whether the message SID matched a notification we sent.
  """

  use CleanerCrmWeb, :controller

  alias CleanerCrm.Notifications

  def status(conn, params) do
    Notifications.handle_delivery_status(params)
    json(conn, %{ok: true})
  end
end
