defmodule CleanerCrmSpex.Story853.Criterion7245Spex do
  @moduledoc """
  Story 853 — Leave a review when the job is done well
  Criterion 7245 — Review request sent ~24h after completion

  The automatic ~24h-later trigger has no user-facing action to drive
  — the spec cannot call `CleanerCrm.Reviews` directly (sealed
  boundary). Mirrors story 837's criterion 7183: rather than backdate
  any row's own timestamp, `Fixtures.run_due_review_requests/1` runs
  the periodic scan with an explicit "as of" time 24 hours after the
  job was completed, the same injectable-`now` seam
  `CleanerCrm.Notifications.ReminderScheduler.scan_and_send/1` already
  uses in production.
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "a review request goes out roughly a day after the visit is completed" do
    scenario "review request sent ~24h after completion" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client's visit was just completed", context do
        client = Fixtures.client_fixture(context.scope)
        job = Fixtures.job_fixture(context.scope, client, %{status: :scheduled})

        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{job.id}")

        job_live
        |> element("[data-test='mark-complete-button']")
        |> render_click()

        # Defensive flush — see criterion 7244's `then_` step for why:
        # forces the trailing `:job_completed` info (and its DB
        # queries) to finish now rather than risk racing this
        # process's own DB sandbox teardown.
        _html = render(job_live)

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "roughly 24 hours pass", context do
        as_of = DateTime.add(DateTime.utc_now(), 24 * 60 * 60, :second)
        Fixtures.run_due_review_requests(as_of)

        {:ok, context}
      end

      then_ "the client receives a review request", context do
        assert_email_sent(to: context.client.email, subject: ~r/review/i)

        {:ok, context}
      end
    end
  end
end
