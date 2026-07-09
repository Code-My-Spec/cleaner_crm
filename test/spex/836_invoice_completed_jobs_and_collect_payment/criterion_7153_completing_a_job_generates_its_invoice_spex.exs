defmodule CleanerCrmSpex.Story836.Criterion7153Spex do
  @moduledoc """
  Story 836 — Invoice completed jobs and collect payment
  Criterion 7153 — Completing a job generates its invoice
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "marking a job complete generates its invoice" do
    scenario "completing a job generates its invoice" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a scheduled job has an agreed price of $150", context do
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            agreed_price: Decimal.new("150.00"),
            status: :scheduled
          })

        {:ok, Map.merge(context, %{client: client, job: job})}
      end

      when_ "the cleaner marks the job complete", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        job_live
        |> element("[data-test='mark-complete-button']")
        |> render_click()

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "the job is shown as complete to the cleaner", context do
        assert render(context.job_live) =~ "Complete"

        {:ok, context}
      end

      then_ "an invoice for $150 appears in the owner's billing queue", context do
        {:ok, _invoices_live, html} = live(context.conn, ~p"/app/invoices")

        assert html =~ context.client.name
        assert html =~ "$150.00"

        {:ok, context}
      end
    end
  end
end
