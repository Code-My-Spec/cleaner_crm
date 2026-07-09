defmodule CleanerCrmSpex.Story837.Criterion7187Spex do
  @moduledoc """
  Story 837 — Send automated appointment reminders to clients
  Criterion 7187 — Client confirms the appointment

  The reminder send itself is covered end-to-end by criterion 7183;
  this spec's subject is the confirm action's effect, so the
  already-sent reminder is seeded directly via
  `CleanerCrmSpex.Fixtures.notification_fixture/4`.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "confirming via the reminder marks the appointment confirmed" do
    scenario "client confirms the appointment" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client received a reminder for an unconfirmed appointment", context do
        client = Fixtures.client_fixture(context.scope, %{name: "Priya Nair"})
        job = Fixtures.job_fixture(context.scope, client, %{status: :scheduled})
        notification = Fixtures.notification_fixture(context.scope, client, job)

        {:ok, Map.merge(context, %{client: client, job: job, notification: notification})}
      end

      when_ "the client taps confirm", context do
        confirm_conn =
          Phoenix.ConnTest.build_conn()
          |> get(~p"/reminders/confirm/#{context.notification.token}")

        {:ok, Map.put(context, :confirm_conn, confirm_conn)}
      end

      then_ "the appointment is marked confirmed for the client", context do
        assert Phoenix.ConnTest.html_response(context.confirm_conn, 200) =~ "Confirmed"

        {:ok, context}
      end

      then_ "the owner sees it as confirmed on the schedule board", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/app/schedule")

        assert has_element?(board_live, "[data-test='job-#{context.job.id}']", "Confirmed")

        {:ok, context}
      end
    end
  end
end
