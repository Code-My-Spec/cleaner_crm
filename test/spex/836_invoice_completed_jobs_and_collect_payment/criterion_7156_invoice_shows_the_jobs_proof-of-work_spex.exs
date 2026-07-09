defmodule CleanerCrmSpex.Story836.Criterion7156Spex do
  @moduledoc """
  Story 836 — Invoice completed jobs and collect payment
  Criterion 7156 — Invoice shows the job's proof-of-work
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "attaching a completed job's proof-of-work to its invoice" do
    scenario "invoice shows the job's proof-of-work" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a job was completed with a finished checklist and before/after photos", context do
        client = Fixtures.client_fixture(context.scope)
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)
        invoice = Fixtures.invoice_fixture(context.scope, job, %{amount: job.agreed_price})

        {:ok, Map.merge(context, %{client: client, job: job, invoice: invoice})}
      end

      when_ "the invoice for that job is opened", context do
        {:ok, invoice_live, html} = live(context.conn, ~p"/app/invoices/#{context.invoice.id}")

        {:ok, Map.merge(context, %{invoice_live: invoice_live, invoice_html: html})}
      end

      then_ "the completed checklist is attached to the invoice", context do
        assert context.invoice_html =~ "Kitchen counters wiped down"
        assert context.invoice_html =~ "Bathrooms sanitized"

        {:ok, context}
      end

      then_ "the before/after photos are attached to the invoice as dispute evidence", context do
        assert has_element?(context.invoice_live, "[data-test='proof-of-work-photo']")

        {:ok, context}
      end
    end
  end
end
