defmodule CleanerCrmWeb.QualityLive.TemplatesTest do
  @moduledoc """
  Covers issue 35ce3856: `CleanerCrm.Quality.ChecklistTemplate` had no
  UI to create one and no wiring to a job's checklist, so proof-of-work
  was unreachable through the live product without seeded data. No
  spex/BDD story owns this surface, so it's covered here instead.
  """

  use CleanerCrmTest.ConnCase

  import Phoenix.LiveViewTest

  alias CleanerCrm.Accounts
  alias CleanerCrm.ClientsFixtures
  alias CleanerCrm.Quality
  alias CleanerCrm.SchedulingFixtures
  alias CleanerCrm.Users.Scope

  setup %{conn: conn} do
    user = CleanerCrm.UsersFixtures.user_fixture()
    scope = Scope.for_user(user)
    {:ok, account} = Accounts.create_account(scope, %{name: "Sparkle Co"})
    scope = %{scope | active_account_id: account.id, active_account: account}

    client = ClientsFixtures.client_fixture(scope, %{name: "Riverside Bungalow"})
    property = ClientsFixtures.property_fixture(scope, client, %{service_address: "1 Main St"})

    conn = log_in_user(conn, user)

    %{conn: conn, scope: scope, client: client, property: property}
  end

  test "create_checklist_template supports sort/drop params and a blank property_id",
       %{scope: scope, property: property} do
    {:ok, template} =
      Quality.create_checklist_template(scope, %{
        "name" => "Standard Clean",
        "property_id" => "",
        "items" => %{
          "0" => %{"room" => "Kitchen", "task" => "Wipe counters", "required" => "true"},
          "1" => %{"room" => "Bathroom", "task" => "Sanitize", "required" => "false"}
        }
      })

    assert template.property_id == nil
    assert length(template.items) == 2

    {:ok, updated} =
      Quality.update_checklist_template(scope, template, %{
        "property_id" => property.id,
        "items" => %{
          "0" => %{"room" => "Kitchen", "task" => "Wipe counters", "required" => "true"},
          "1" => %{"room" => "Bathroom", "task" => "Sanitize", "required" => "false"}
        },
        "items_drop" => ["1"]
      })

    assert updated.property_id == property.id
    assert length(updated.items) == 1
    assert hd(updated.items).task == "Wipe counters"
  end

  test "an empty-items create_checklist picks up the job's property template",
       %{scope: scope, client: client, property: property} do
    {:ok, _template} =
      Quality.create_checklist_template(scope, %{
        "name" => "Standard Clean",
        "property_id" => property.id,
        "items" => %{
          "0" => %{"room" => "Kitchen", "task" => "Wipe counters", "required" => "true"},
          "1" => %{"room" => "Bathroom", "task" => "Sanitize", "required" => "false"}
        }
      })

    job =
      SchedulingFixtures.job_fixture(scope, property, %{
        client_id: client.id,
        status: :in_progress
      })

    {:ok, checklist} = Quality.create_checklist(scope, job, [])

    assert length(checklist.items) == 2
    assert Enum.sort(Enum.map(checklist.items, & &1.task)) == ["Sanitize", "Wipe counters"]
    assert checklist.checklist_template_id != nil
  end

  test "new form saves a template", %{conn: conn, property: property} do
    {:ok, _index_live, html} = live(conn, ~p"/quality/templates")
    assert html =~ "No checklist templates yet."

    {:ok, new_live, _html} = live(conn, ~p"/quality/templates/new")

    submit_result =
      new_live
      |> form("[data-test='checklist-template-form']",
        template: %{"name" => "Standard Clean", "property_id" => property.id}
      )
      |> render_submit()

    {:ok, _index_live2, html2} = follow_redirect(submit_result, conn, ~p"/quality/templates")
    assert html2 =~ "Standard Clean"
    assert html2 =~ property.service_address
  end

  test "Add Task control appends a blank row and it can be filled in and saved", %{
    conn: conn,
    scope: scope,
    property: property
  } do
    {:ok, new_live, _html} = live(conn, ~p"/quality/templates/new")

    refute has_element?(new_live, "[data-test='template-item-0']")

    # The "Add Task" control is a native checkbox (see
    # `TemplateFormComponent`), so checking it fires a real "change"
    # event through the existing `phx-change="validate"` binding —
    # no synthetic JS runtime needed to exercise this in LiveViewTest.
    new_live
    |> form("[data-test='checklist-template-form']", template: %{"items_sort" => ["new"]})
    |> render_change()

    assert has_element?(new_live, "[data-test='template-item-0']")

    submit_result =
      new_live
      |> form("[data-test='checklist-template-form']",
        template: %{
          "name" => "Standard Clean",
          "property_id" => property.id,
          "items" => %{
            "0" => %{"room" => "Kitchen", "task" => "Wipe counters", "required" => "true"}
          }
        }
      )
      |> render_submit()

    {:ok, _index_live2, _html2} = follow_redirect(submit_result, conn, ~p"/quality/templates")

    [template] = Quality.list_checklist_templates(scope)
    assert length(template.items) == 1
    assert hd(template.items).task == "Wipe counters"
  end

  test "edit form renders a template's persisted rows and removes one on save", %{
    conn: conn,
    scope: scope,
    property: property
  } do
    {:ok, template} =
      Quality.create_checklist_template(scope, %{
        "name" => "Standard Clean",
        "property_id" => property.id,
        "items" => %{
          "0" => %{"room" => "Kitchen", "task" => "Wipe counters", "required" => "true"},
          "1" => %{"room" => "Bathroom", "task" => "Sanitize", "required" => "false"}
        }
      })

    {:ok, edit_live, edit_html} = live(conn, ~p"/quality/templates/#{template.id}/edit")
    assert edit_html =~ "Wipe counters"
    assert edit_html =~ "Sanitize"
    assert has_element?(edit_live, "[data-test='template-item-0']")
    assert has_element?(edit_live, "[data-test='template-item-1']")

    edit_submit_result =
      edit_live
      |> form("[data-test='checklist-template-form']", template: %{"items_drop" => ["1"]})
      |> render_submit()

    {:ok, _index_live, _html} = follow_redirect(edit_submit_result, conn, ~p"/quality/templates")

    reloaded = Quality.get_checklist_template!(scope, template.id)

    assert length(reloaded.items) == 1
    assert hd(reloaded.items).task == "Wipe counters"
  end
end
