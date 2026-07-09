defmodule CleanerCrmSpex.Story853.Criterion7244Spex do
  @moduledoc """
  Story 853 — Leave a review when the job is done well
  Criterion 7244 — Thank-you sent on job completion

  Mirrors story 836's criterion 7153 for driving the real "mark
  complete" flow on `FieldLive.Job`. Assumes a thank-you email whose
  subject contains "thank" (`CleanerCrm.Reviews`'s `ReviewNotifier`,
  by analogy with `ReceiptNotifier`/`ReminderNotifier`).
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "completing a job sends the client an immediate thank-you" do
    scenario "thank-you sent on job completion" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client has a scheduled job", context do
        client = Fixtures.client_fixture(context.scope)
        job = Fixtures.job_fixture(context.scope, client, %{status: :scheduled})

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "the cleaner marks the job complete", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/field/jobs/#{context.job.id}")

        job_live
        |> element("[data-test='mark-complete-button']")
        |> render_click()

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "the client immediately receives a thank-you note", context do
        assert_email_sent(to: context.client.email, subject: ~r/thank/i)

        # `mark_complete` sends itself a trailing `:job_completed` info
        # (see `ChecklistComponent`) that's still queued after
        # `render_click` returns. A synchronous `render/1` forces it to
        # be processed now, before this test process exits — otherwise
        # its DB queries can still be in flight when the sandbox
        # connection is torn down, corrupting the pool connection for
        # whichever spec runs next.
        _html = render(context.job_live)

        {:ok, context}
      end
    end
  end
end
