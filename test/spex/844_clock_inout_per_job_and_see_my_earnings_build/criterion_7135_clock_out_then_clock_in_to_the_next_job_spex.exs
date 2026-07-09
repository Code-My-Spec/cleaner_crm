defmodule CleanerCrmSpex.Story844.Criterion7135Spex do
  @moduledoc """
  Story 844 — Clock in/out per job and see my earnings build
  Criterion 7135 — Clock out then clock in to the next job
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner clocks out of one job and into the next" do
    scenario "clock out then clock in to the next job" do
      given_ "the owner has an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{scope: scope, account: account})}
      end

      given_ "I am a cleaner assigned to the Smith job and a next job", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        smith_client = Fixtures.client_fixture(context.scope, %{name: "Smith"})
        next_client = Fixtures.client_fixture(context.scope, %{name: "Next Stop"})

        smith_job =
          Fixtures.job_fixture(context.scope, smith_client, %{
            cleaner_id: cleaner.id,
            status: :scheduled
          })

        next_job =
          Fixtures.job_fixture(context.scope, next_client, %{
            cleaner_id: cleaner.id,
            status: :scheduled
          })

        conn = Fixtures.log_in_user(context.conn, cleaner)

        {:ok, Map.merge(context, %{smith_job: smith_job, next_job: next_job, conn: conn})}
      end

      given_ "I am clocked in to the Smith job", context do
        {:ok, smith_job_live, _html} =
          live(context.conn, ~p"/field/jobs/#{context.smith_job.id}")

        smith_job_live
        |> element("[data-test='clock-in-button']")
        |> render_click()

        {:ok, Map.put(context, :smith_job_live, smith_job_live)}
      end

      when_ "I tap Clock Out on the Smith job", context do
        context.smith_job_live
        |> element("[data-test='clock-out-button']")
        |> render_click()

        {:ok, context}
      end

      then_ "the Smith job's time is closed", context do
        assert render(context.smith_job_live) =~ "Clocked out"
        assert has_element?(context.smith_job_live, "[data-test='worked-time']")

        {:ok, context}
      end

      when_ "I tap Clock In on my next job", context do
        {:ok, next_job_live, _html} = live(context.conn, ~p"/field/jobs/#{context.next_job.id}")

        next_job_live
        |> element("[data-test='clock-in-button']")
        |> render_click()

        {:ok, Map.put(context, :next_job_live, next_job_live)}
      end

      then_ "the next job begins accumulating time", context do
        assert render(context.next_job_live) =~ "Clocked in"
        assert has_element?(context.next_job_live, "[data-test='elapsed-time']")

        {:ok, context}
      end
    end
  end
end
