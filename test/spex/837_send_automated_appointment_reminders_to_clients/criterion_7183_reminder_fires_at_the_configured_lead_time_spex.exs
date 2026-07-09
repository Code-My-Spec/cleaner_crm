defmodule CleanerCrmSpex.Story837.Criterion7183Spex do
  @moduledoc """
  Story 837 — Send automated appointment reminders to clients
  Criterion 7183 — Reminder fires at the configured lead time

  The scheduler's automatic trigger has no user-facing action to
  drive — the spec cannot call `CleanerCrm.Notifications` directly
  (sealed boundary). The appointment is pinned to the exact
  lead-time boundary (24 hours from now) so any conforming
  implementation's periodic check has already fired the send by the
  time `then_` asserts; `when_` marks that moment rather than
  performing an action. This is the one spec that proves the
  automatic trigger end-to-end — criteria 7185–7189 seed an
  already-sent reminder instead of re-driving it.
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "an appointment reminder fires automatically at the configured lead time" do
    scenario "reminder fires at the configured lead time" do
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

      given_ "a client has an appointment 24 hours from now", context do
        client =
          Fixtures.client_fixture(context.scope, %{
            email: "jamie-#{System.unique_integer([:positive])}@example.com",
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

      when_ "the clock reaches the configured lead time before the appointment", context do
        {:ok, context}
      end

      then_ "an appointment reminder is automatically sent to the client", context do
        assert_email_sent(to: context.client.email)

        {:ok, context}
      end
    end
  end

  defp lead_time_boundary, do: DateTime.add(DateTime.utc_now(), 24 * 60 * 60, :second)
end
