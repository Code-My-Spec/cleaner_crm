defmodule CleanerCrmSpex.Story843.Criterion7203Spex do
  @moduledoc """
  Story 843 — Get loud, acknowledged alerts when my schedule changes
  Criterion 7203 — Push failure falls back to SMS

  "My push notification cannot be delivered" is modeled as the cleaner
  having no push channel registered (`push_enabled: false`) — there is
  no push-registration flow anywhere in this app, so a cleaner who has
  never enabled push is the natural, real-world precondition rather
  than a fabricated delivery-status callback. "The system sends the
  change" re-drives the same real trigger as criterion 7190 (moving a
  job on `ScheduleLive.Board`); the fallback is observed via the
  board's per-job notification-channel control
  (`[data-test='job-<id>-notification-channel']`), never a live
  Twilio call.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a schedule change falls back to SMS when push cannot be delivered" do
    scenario "push failure falls back to SMS" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a schedule change needs to reach me", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com",
            push_enabled: false
          })

        cleaner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), cleaner)
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            scheduled_date: Date.utc_today(),
            start_time: ~T[13:00:00],
            end_time: ~T[14:30:00]
          })

        {:ok, Map.merge(context, %{cleaner: cleaner, cleaner_conn: cleaner_conn, job: job})}
      end

      given_ "my push notification cannot be delivered", context do
        {:ok, context}
      end

      when_ "the system sends the change", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/schedule")

        board_live
        |> element("[data-test='job-#{context.job.id}-start-time-input']")
        |> render_change(%{"start_time" => "15:00"})

        {:ok, context}
      end

      then_ "it falls back to sending me an SMS with the change details", context do
        {:ok, board_live, _html} = live(context.conn, ~p"/schedule")

        assert has_element?(
                 board_live,
                 "[data-test='job-#{context.job.id}-notification-channel']",
                 "SMS"
               )

        assert has_element?(
                 board_live,
                 "[data-test='job-#{context.job.id}-notification-channel']",
                 "3:00 PM"
               )

        {:ok, context}
      end
    end
  end
end
