defmodule CleanerCrmSpex.Story837.Criterion7188Spex do
  @moduledoc """
  Story 837 — Send automated appointment reminders to clients
  Criterion 7188 — Client requests a reschedule

  As in criterion 7187, the reminder is seeded directly via
  `CleanerCrmSpex.Fixtures.notification_fixture/4` since sending it
  is covered end-to-end by criterion 7183; this spec's subject is the
  reschedule action's effect.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "requesting reschedule via the reminder flags the appointment and notifies the owner" do
    scenario "client requests a reschedule" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client received a reminder for an upcoming appointment", context do
        client = Fixtures.client_fixture(context.scope, %{name: "Sam Okafor"})
        job = Fixtures.job_fixture(context.scope, client, %{status: :scheduled})
        notification = Fixtures.notification_fixture(context.scope, client, job)

        {:ok, Map.merge(context, %{client: client, job: job, notification: notification})}
      end

      when_ "the client taps reschedule", context do
        reschedule_conn =
          Phoenix.ConnTest.build_conn()
          |> get(~p"/reminders/reschedule/#{context.notification.token}")

        {:ok, Map.put(context, :reschedule_conn, reschedule_conn)}
      end

      then_ "the appointment is flagged for reschedule", context do
        assert Phoenix.ConnTest.html_response(context.reschedule_conn, 200) =~
                 "Reschedule requested"

        {:ok, context}
      end

      then_ "the owner is notified to rebook it, protecting route density", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/app/schedule")

        assert has_element?(board_live, "[data-test='job-#{context.job.id}']", "Needs reschedule")

        {:ok, context}
      end
    end
  end
end
