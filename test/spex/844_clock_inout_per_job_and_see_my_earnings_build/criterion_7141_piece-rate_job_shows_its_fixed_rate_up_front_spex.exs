defmodule CleanerCrmSpex.Story844.Criterion7141Spex do
  @moduledoc """
  Story 844 — Clock in/out per job and see my earnings build
  Criterion 7141 — Piece-rate job shows its fixed rate up front
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a piece-rate job shows its fixed earnings before the cleaner starts" do
    scenario "piece-rate job shows its fixed rate up front" do
      given_ "the owner has an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{scope: scope, account: account})}
      end

      given_ "the Jones job pays a fixed piece-rate of $60", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        client = Fixtures.client_fixture(context.scope, %{name: "Jones"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            pay_type: :piece_rate,
            piece_rate_cents: 6000,
            status: :scheduled
          })

        conn = Fixtures.log_in_user(context.conn, cleaner)

        {:ok, Map.merge(context, %{job: job, conn: conn})}
      end

      when_ "I open the job before starting", context do
        {:ok, job_live, html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        {:ok, Map.merge(context, %{job_live: job_live, html: html})}
      end

      then_ "it clearly shows I will earn $60 for this job", context do
        assert context.html =~ "$60.00"

        {:ok, context}
      end

      then_ "the amount does not depend on how long the job takes", context do
        downcased = String.downcase(context.html)

        refute downcased =~ "/hr"
        refute downcased =~ "per hour"

        {:ok, context}
      end
    end
  end
end
