defmodule CleanerCrm.Notifications.Delivery.TwilioTest do
  @moduledoc """
  Guards the Twilio adapter's graceful-degradation behavior: every env
  except prod carries no real Twilio credentials (see `config/runtime.exs`
  — the config block is unconditional, but the values are nil there),
  so `send_sms/2` must get `{:error, :not_configured}` back, never a
  raised `KeyError` that would crash the reminder scan (issue
  009fb5de) and skip the email fallback entirely.
  """

  use ExUnit.Case, async: false

  alias CleanerCrm.Notifications.Delivery.Twilio

  setup do
    original = Application.get_env(:cleaner_crm, Twilio, [])
    on_exit(fn -> Application.put_env(:cleaner_crm, Twilio, original) end)
    :ok
  end

  describe "send_sms/2 with no Twilio credentials configured" do
    test "returns an error tuple instead of raising" do
      Application.put_env(:cleaner_crm, Twilio, [])

      assert {:error, :not_configured} = Twilio.send_sms("+15555550100", "hi")
    end

    test "returns an error tuple when credentials are present but blank" do
      Application.put_env(:cleaner_crm, Twilio,
        account_sid: "",
        auth_token: "",
        from_number: ""
      )

      assert {:error, :not_configured} = Twilio.send_sms("+15555550100", "hi")
    end

    test "returns an error tuple when only some credentials are set" do
      Application.put_env(:cleaner_crm, Twilio, account_sid: "AC123")

      assert {:error, :not_configured} = Twilio.send_sms("+15555550100", "hi")
    end
  end
end
