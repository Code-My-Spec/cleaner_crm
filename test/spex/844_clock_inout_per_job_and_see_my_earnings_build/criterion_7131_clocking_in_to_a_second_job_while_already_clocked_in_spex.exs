defmodule CleanerCrmSpex.Story844.Criterion7131Spex do
  @moduledoc """
  Story 844 — Clock in/out per job and see my earnings build
  Criterion 7131 — Clocking in to a second job while already clocked in
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner can be clocked in to only one job at a time" do
    scenario "clocking in to a second job while already clocked in" do
      given_ "the owner has an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{scope: scope, account: account})}
      end

      given_ "I am a cleaner assigned to a 9:00 AM Smith job and an 11:00 AM job", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        smith_client = Fixtures.client_fixture(context.scope, %{name: "Smith"})
        next_client = Fixtures.client_fixture(context.scope, %{name: "Garcia"})

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

      given_ "I am already clocked in to the Smith job", context do
        {:ok, smith_job_live, _html} =
          live(context.conn, ~p"/field/jobs/#{context.smith_job.id}")

        smith_job_live
        |> element("[data-test='clock-in-button']")
        |> render_click()

        {:ok, Map.put(context, :smith_job_live, smith_job_live)}
      end

      when_ "I open my 11:00 AM job and tap Clock In", context do
        {:ok, next_job_live, _html} = live(context.conn, ~p"/field/jobs/#{context.next_job.id}")

        next_job_live
        |> element("[data-test='clock-in-button']")
        |> render_click()

        {:ok, Map.put(context, :next_job_live, next_job_live)}
      end

      then_ "I am warned that I am still clocked in to the Smith job and must clock out there first",
            context do
        downcased = context.next_job_live |> render() |> String.downcase()

        assert downcased =~ "smith"
        assert downcased =~ "clock out"

        {:ok, context}
      end

      then_ "the new job has not started accumulating time", context do
        refute has_element?(context.next_job_live, "[data-test='elapsed-time']")

        {:ok, context}
      end
    end
  end
end
