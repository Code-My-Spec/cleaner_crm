defmodule CleanerCrmSpex.Story837.Criterion7189Spex do
  @moduledoc """
  Story 837 — Send automated appointment reminders to clients
  Criterion 7189 — SMS reminder is undeliverable and falls back to email

  The reminder send is seeded directly via
  `CleanerCrmSpex.Fixtures.notification_fixture/4` (covered
  end-to-end by criteria 7183/7185); this spec's subject is the
  provider delivery-status callback and the fallback it triggers.
  External SMS delivery status arrives the same way Stripe's does in
  story 836 — a provider webhook, never a live Twilio call.
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "an undeliverable SMS reminder falls back to email and flags the owner" do
    scenario "SMS reminder is undeliverable and falls back to email" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client prefers SMS but has blocked the reminder sender's number", context do
        client =
          Fixtures.client_fixture(context.scope, %{
            phone: "+15555550199",
            email: "dana-#{System.unique_integer([:positive])}@example.com",
            preferred_channel: :sms
          })

        job = Fixtures.job_fixture(context.scope, client, %{status: :scheduled})

        notification =
          Fixtures.notification_fixture(context.scope, client, job, %{
            channel: :sms,
            provider_message_id: "sms_test_undelivered_#{System.unique_integer([:positive])}"
          })

        {:ok, Map.merge(context, %{client: client, job: job, notification: notification})}
      end

      when_ "the SMS reminder fails to deliver", context do
        payload = %{
          "MessageSid" => context.notification.provider_message_id,
          "MessageStatus" => "undelivered",
          "ErrorCode" => "30003"
        }

        response =
          Phoenix.ConnTest.build_conn()
          |> Plug.Conn.put_req_header("content-type", "application/json")
          |> post("/webhooks/twilio", payload)
          |> Phoenix.ConnTest.json_response(200)

        {:ok, Map.put(context, :webhook_response, response)}
      end

      then_ "the reminder falls back to the client's email", context do
        assert_email_sent(to: context.client.email)

        {:ok, context}
      end

      then_ "the owner is flagged that the SMS did not reach the client", context do
        {:ok, _reminders_live, html} = live(context.conn, ~p"/app/reminders")

        assert html =~ context.client.phone
        assert html =~ "undeliver"

        {:ok, context}
      end
    end
  end
end
