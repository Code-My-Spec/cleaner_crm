defmodule CleanerCrm.Notifications.Delivery.Twilio do
  @moduledoc """
  Sends SMS via the Twilio Messages REST API using `Req` directly —
  no `ex_twilio` dependency, per the sms-delivery ADR. Configured via
  `config :cleaner_crm, CleanerCrm.Notifications.Delivery.Twilio,
  account_sid:, auth_token:, from_number:, status_callback_url:`.
  """

  @behaviour CleanerCrm.Notifications.Delivery

  @impl true
  def send_sms(phone, body) do
    config = Application.get_env(:cleaner_crm, __MODULE__, [])

    with {:ok, account_sid} <- fetch_credential(config, :account_sid),
         {:ok, auth_token} <- fetch_credential(config, :auth_token),
         {:ok, from_number} <- fetch_credential(config, :from_number) do
      form =
        %{"To" => phone, "From" => from_number, "Body" => body}
        |> maybe_put_status_callback(config[:status_callback_url])

      [
        base_url: "https://api.twilio.com/2010-04-01",
        auth: {:basic, "#{account_sid}:#{auth_token}"}
      ]
      |> Req.new()
      |> Req.post(url: "/Accounts/#{account_sid}/Messages.json", form: form)
      |> handle_response()
    end
  end

  # Every env carries this config unconditionally (see runtime.exs) so
  # this adapter always has *something* to read, but dev/test/CI have
  # no real Twilio credentials — a missing/blank value there must
  # return an error tuple the caller can fall back on, never raise.
  defp fetch_credential(config, key) do
    case Keyword.get(config, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, :not_configured}
    end
  end

  defp maybe_put_status_callback(form, nil), do: form
  defp maybe_put_status_callback(form, url), do: Map.put(form, "StatusCallback", url)

  defp handle_response({:ok, %Req.Response{status: 201, body: %{"sid" => sid}}}),
    do: {:ok, %{provider_message_id: sid}}

  defp handle_response({:ok, %Req.Response{status: status, body: body}}),
    do: {:error, {status, body}}

  defp handle_response({:error, reason}), do: {:error, reason}
end
