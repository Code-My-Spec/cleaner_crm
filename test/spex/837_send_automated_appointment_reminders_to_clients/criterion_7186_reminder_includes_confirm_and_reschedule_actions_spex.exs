defmodule CleanerCrmSpex.Story837.Criterion7186Spex do
  @moduledoc """
  Story 837 — Send automated appointment reminders to clients
  Criterion 7186 — Reminder includes confirm and reschedule actions

  Re-drives the lead-time trigger (as in criterion 7183) so the
  assertion can inspect the actual delivered message body for both
  action links, rather than trusting a seeded row's shape.
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "every reminder gives the client confirm and reschedule actions" do
    scenario "reminder includes confirm and reschedule actions" do
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

      given_ "a client receives an appointment reminder", context do
        client =
          Fixtures.client_fixture(context.scope, %{
            email: "morgan-#{System.unique_integer([:positive])}@example.com",
            preferred_channel: :email
          })

        due_at = lead_time_boundary()

        job =
          Fixtures.job_fixture(context.scope, client, %{
            scheduled_date: DateTime.to_date(due_at),
            start_time: DateTime.to_time(due_at)
          })

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "the client opens it", context do
        {:ok, context}
      end

      then_ "the reminder presents a confirm action and a reschedule action the client can tap",
            context do
        assert_email_sent(fn email ->
          email.html_body =~ ~r{href="[^"]*confirm[^"]*"}i and
            email.html_body =~ ~r{href="[^"]*reschedule[^"]*"}i
        end)

        {:ok, context}
      end
    end
  end

  defp lead_time_boundary, do: DateTime.add(DateTime.utc_now(), 24 * 60 * 60, :second)
end
