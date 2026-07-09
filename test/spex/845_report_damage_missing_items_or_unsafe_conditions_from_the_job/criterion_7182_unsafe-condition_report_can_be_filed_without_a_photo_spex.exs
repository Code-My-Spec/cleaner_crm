defmodule CleanerCrmSpex.Story845.Criterion7182Spex do
  @moduledoc """
  Story 845 — Report damage, missing items, or unsafe conditions from the job
  Criterion 7182 — Unsafe-condition report can be filed without a photo
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner can file an unsafe-condition report without attaching a photo" do
    scenario "unsafe-condition report can be filed without a photo" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        owner_conn = Fixtures.log_in_user(context.conn, user)

        {:ok,
         Map.merge(context, %{owner_conn: owner_conn, user: user, scope: scope, account: account})}
      end

      given_ "cleaner Ana is logged in on her assigned, in-progress job", context do
        client = Fixtures.client_fixture(context.scope)

        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{email: "ana@example.com"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            status: :in_progress
          })

        conn = Fixtures.log_in_user(build_conn(), cleaner)

        {:ok, Map.merge(context, %{client: client, cleaner: cleaner, job: job, conn: conn})}
      end

      when_ "Ana files an unsafe-condition report with only a description, no photo", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        job_live
        |> form("[data-test='incident-report-form']",
          incident: %{
            type: "unsafe_condition",
            description: "Loose handrail on the exterior stairs"
          }
        )
        |> render_submit()

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "the report is filed successfully without requiring a photo", context do
        assert has_element?(context.job_live, "[data-test='incident-report-item']")
        assert render(context.job_live) =~ "Loose handrail on the exterior stairs"

        {:ok, context}
      end

      then_ "the owner sees the unsafe-condition report when reviewing incidents", context do
        {:ok, _review_live, html} = live(context.owner_conn, ~p"/app/quality")

        assert html =~ "Loose handrail on the exterior stairs"

        {:ok, context}
      end
    end
  end
end
