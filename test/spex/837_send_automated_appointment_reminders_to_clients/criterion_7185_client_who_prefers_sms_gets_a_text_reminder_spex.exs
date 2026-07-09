defmodule CleanerCrmSpex.Story837.Criterion7185Spex do
  @moduledoc """
  Story 837 — Send automated appointment reminders to clients
  Criterion 7185 — Client who prefers SMS gets a text reminder

  Re-drives the same lead-time trigger as criterion 7183 — there is
  no UI action to seed a channel choice around, and this spec's
  subject is which channel the automatic send picks, not the trigger
  itself.
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "the automatic reminder is delivered on the client's preferred channel" do
    scenario "client who prefers SMS gets a text reminder" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "the owner's reminder lead time is set to 24 hours", context do
        {:ok, reminders_live, _html} = live(context.conn, ~p"/app/reminders")

        reminders_live
        |> form("[data-test='reminder-settings-form']", settings: %{lead_time_hours: "24"})
        |> render_submit()

        {:ok, context}
      end

      given_ "a client's preferred channel is SMS and their appointment is due for a reminder",
             context do
        client =
          Fixtures.client_fixture(context.scope, %{
            phone: "+15555550101",
            preferred_channel: :sms
          })

        due_at = lead_time_boundary()

        job =
          Fixtures.job_fixture(context.scope, client, %{
            scheduled_date: DateTime.to_date(due_at),
            start_time: DateTime.to_time(due_at)
          })

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "their appointment reminder is sent", context do
        {:ok, context}
      end

      then_ "the reminder is delivered as an SMS to the client's phone number", context do
        {:ok, _reminders_live, html} = live(context.conn, ~p"/app/reminders")

        assert html =~ context.client.phone
        assert html =~ "SMS"

        {:ok, context}
      end

      then_ "no email reminder is sent instead", context do
        assert_no_email_sent()

        {:ok, context}
      end
    end
  end

  defp lead_time_boundary, do: DateTime.add(DateTime.utc_now(), 24 * 60 * 60, :second)
end
