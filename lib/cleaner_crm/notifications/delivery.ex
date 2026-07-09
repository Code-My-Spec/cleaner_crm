defmodule CleanerCrm.Notifications.Delivery do
  @moduledoc """
  Provider abstraction for SMS delivery, with a `Twilio` adapter (Req,
  no `ex_twilio`) for production and a `Test` adapter swapped in during
  tests. Email keeps flowing through `CleanerCrm.Mailer` (Swoosh) —
  this behaviour only covers SMS, per the sms-delivery ADR.
  """

  @callback send_sms(phone :: String.t(), body :: String.t()) ::
              {:ok, %{provider_message_id: String.t()}} | {:error, term()}

  def send_sms(phone, body), do: adapter().send_sms(phone, body)

  defp adapter do
    Application.get_env(
      :cleaner_crm,
      :sms_delivery_adapter,
      CleanerCrm.Notifications.Delivery.Twilio
    )
  end
end
