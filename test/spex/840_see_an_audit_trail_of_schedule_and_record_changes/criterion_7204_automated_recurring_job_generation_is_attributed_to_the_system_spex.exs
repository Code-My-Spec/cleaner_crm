defmodule CleanerCrmSpex.Story840.Criterion7204Spex do
  @moduledoc """
  Story 840 — See an audit trail of schedule and record changes
  Criterion 7204 — Automated recurring job generation is attributed to
  the system: Dana authors the recurring plan, but the individual job
  occurrences it materializes are created by an automated process with
  no human involved, so each of those audit entries must name the
  system as actor rather than Dana or a blank author.

  Assumes `CleanerCrmWeb.ScheduleLive.PlanFormComponent` (opened from
  `/schedule/plans/new`, per story 833's own specs) exposes a
  `[data-test='plan-form']` (submitted via `render_change`) and a
  `[data-test='save-plan-button']` that saves the plan and, per
  criterion 7143, materializes its job occurrences immediately.
  Assumes `CleanerCrmWeb.AuditLive` (`/audit`) renders one entry per
  materialized job and names its actor "System" when no human made the
  change.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "automated recurring job generation is attributed to the system" do
    scenario "jobs materialized by a saved weekly plan are logged as system-authored" do
      given_ "office staffer Dana is logged in with an active account", context do
        user =
          Fixtures.user_fixture(%{
            email: "dana-#{System.unique_integer([:positive])}@example.com"
          })

        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client's property and an available cleaner exist", context do
        client_path = create_client(context.conn, "Riverside HOA")

        property_path =
          create_property(context.conn, client_path, %{service_address: "9 River Rd"})

        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "sam-#{System.unique_integer([:positive])}@example.com"
          })

        {:ok, Map.merge(context, %{property_id: id_from_path(property_path), cleaner: cleaner})}
      end

      when_ "Dana creates a weekly recurring plan for that property", context do
        {:ok, plan_live, _html} = live(context.conn, ~p"/schedule/plans/new")

        plan_live
        |> form("[data-test='plan-form']",
          plan: %{
            property_id: context.property_id,
            cleaner_id: context.cleaner.id,
            recurrence: "weekly",
            start_date: Date.to_iso8601(first_visit_date()),
            occurrence_count: 3
          }
        )
        |> render_change()

        plan_live
        |> element("[data-test='save-plan-button']")
        |> render_click()

        {:ok, context}
      end

      then_ "the audit trail attributes every materialized job to the System, not Dana",
            context do
        {:ok, _audit_live, html} = live(context.conn, ~p"/audit")

        assert html =~ "Riverside HOA"
        assert length(Regex.scan(~r/System/, html)) >= 3

        {:ok, context}
      end
    end
  end

  defp first_visit_date, do: Date.add(Date.utc_today(), 14)
  defp id_from_path(path), do: path |> String.split("/") |> List.last()

  defp create_client(conn, name) do
    {:ok, new_live, _html} = live(conn, ~p"/clients/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='client-form']", client: %{name: name})
      |> render_submit()

    path
  end

  defp create_property(conn, client_path, attrs) do
    "/clients/" <> client_id = client_path

    {:ok, new_live, _html} = live(conn, ~p"/clients/#{client_id}/properties/new")

    {:error, {:live_redirect, %{to: path}}} =
      new_live
      |> form("[data-test='property-form']", property: attrs)
      |> render_submit()

    path
  end
end
