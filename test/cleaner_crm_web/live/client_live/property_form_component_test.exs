defmodule CleanerCrmWeb.ClientLive.PropertyFormComponentTest do
  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Audit.AuditEntry
  alias CleanerCrm.Clients.Property
  alias CleanerCrm.Repo
  alias CleanerCrm.Users.Scope
  alias CleanerCrmWeb.ClientLive.PropertyFormComponent

  # Hosts the component in isolation (no router route required) so this
  # test can exercise it before the sibling ClientLive.Index/Show pages
  # exist. Forwards the component's parent notification to the test
  # process so assertions can use `assert_receive`.
  defmodule Host do
    use CleanerCrmWeb, :live_view

    @impl true
    def mount(_params, session, socket) do
      {:ok,
       assign(socket, %{
         test_pid: session["test_pid"],
         current_scope: session["scope"],
         action: session["action"],
         client: session["client"],
         property: session["property"]
       })}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <.live_component
        module={PropertyFormComponent}
        id="property-form"
        current_scope={@current_scope}
        action={@action}
        client={@client}
        property={@property}
      />
      """
    end

    @impl true
    def handle_info({PropertyFormComponent, _} = message, socket) do
      send(socket.assigns.test_pid, message)
      {:noreply, socket}
    end
  end

  defp scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

    %{scope | active_account: account, active_account_id: account.id}
  end

  defp render_host(session) do
    session = Map.put(session, "test_pid", self())
    live_isolated(build_conn(), Host, session: session)
  end

  describe "creating a property with no preselected client" do
    test "renders a client picker listing the account's clients" do
      scope = scope_fixture()
      client_fixture(scope, %{name: "Priya Nair"})

      {:ok, _lv, html} =
        render_host(%{
          "scope" => scope,
          "action" => :new,
          "client" => nil,
          "property" => %Property{}
        })

      assert html =~ "Priya Nair"
    end

    test "rejects a submission with no client selected" do
      scope = scope_fixture()

      {:ok, lv, _html} =
        render_host(%{
          "scope" => scope,
          "action" => :new,
          "client" => nil,
          "property" => %Property{}
        })

      lv
      |> form("[data-test='property-form']", property: %{service_address: "123 Oak St"})
      |> render_submit()

      assert has_element?(lv, "[data-test='property-form']")
      assert has_element?(lv, "[data-test='client-error']", "is required")
    end

    test "creates the property once a client is selected" do
      scope = scope_fixture()
      client = client_fixture(scope, %{name: "Priya Nair"})

      {:ok, lv, _html} =
        render_host(%{
          "scope" => scope,
          "action" => :new,
          "client" => nil,
          "property" => %Property{}
        })

      lv
      |> form("[data-test='property-form']",
        property: %{client_id: client.id, service_address: "77 Maple Ave"}
      )
      |> render_submit()

      assert_receive {PropertyFormComponent, {:saved, %Property{} = property}}
      assert property.client_id == client.id
      assert property.service_address == "77 Maple Ave"
    end
  end

  describe "creating a property under a preselected client" do
    test "does not render a client picker" do
      scope = scope_fixture()
      client = client_fixture(scope)

      {:ok, _lv, html} =
        render_host(%{
          "scope" => scope,
          "action" => :new,
          "client" => client,
          "property" => %Property{}
        })

      refute html =~ "Select a client"
    end

    test "rejects a blank service address" do
      scope = scope_fixture()
      client = client_fixture(scope)

      {:ok, lv, _html} =
        render_host(%{
          "scope" => scope,
          "action" => :new,
          "client" => client,
          "property" => %Property{}
        })

      lv
      |> form("[data-test='property-form']", property: %{service_address: ""})
      |> render_submit()

      assert has_element?(lv, "[data-test='property-form']")
      assert has_element?(lv, "[data-test='service-address-error']", "is required")
    end

    test "saves the property with its access details and notifies the parent" do
      scope = scope_fixture()
      client = client_fixture(scope, %{name: "Devon Ashe"})

      {:ok, lv, _html} =
        render_host(%{
          "scope" => scope,
          "action" => :new,
          "client" => client,
          "property" => %Property{}
        })

      lv
      |> form("[data-test='property-form']",
        property: %{
          service_address: "77 Maple Ave",
          lockbox_code: "4821",
          parking_notes: "driveway only",
          pet_notes: "dog in yard"
        }
      )
      |> render_submit()

      assert_receive {PropertyFormComponent, {:saved, %Property{} = property}}
      assert property.client_id == client.id
      assert property.service_address == "77 Maple Ave"
      assert property.lockbox_code == "4821"
      assert property.parking_notes == "driveway only"
      assert property.pet_notes == "dog in yard"
    end
  end

  describe "editing an existing property" do
    test "preserves untouched fields and updates only the submitted ones" do
      scope = scope_fixture()
      client = client_fixture(scope)

      property =
        property_fixture(scope, client, %{
          service_address: "45 Elm St",
          lockbox_code: "4821"
        })

      {:ok, lv, _html} =
        render_host(%{
          "scope" => scope,
          "action" => :edit,
          "client" => client,
          "property" => property
        })

      lv
      |> form("[data-test='property-form']", property: %{lockbox_code: "9077"})
      |> render_submit()

      assert_receive {PropertyFormComponent, {:saved, %Property{} = updated}}
      assert updated.service_address == "45 Elm St"
      assert updated.lockbox_code == "9077"
    end

    test "records an audit entry naming the changed field, without the code value" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client, %{alarm_code: "1234"})

      {:ok, lv, _html} =
        render_host(%{
          "scope" => scope,
          "action" => :edit,
          "client" => client,
          "property" => property
        })

      lv
      |> form("[data-test='property-form']", property: %{alarm_code: "5678"})
      |> render_submit()

      assert_receive {PropertyFormComponent, {:saved, %Property{} = updated}}
      assert updated.alarm_code == "5678"

      entry = Repo.get_by!(AuditEntry, subject_id: updated.id, subject_type: "Property")
      assert entry.action == "access_details_updated"
      assert entry.actor_id == scope.user.id
      assert entry.new_value["changed_fields"] == ["alarm_code"]
      refute entry.new_value["changed_fields"] |> to_string() =~ "5678"
    end
  end
end
