defmodule CleanerCrmWeb.ClientLive.Show do
  @moduledoc """
  Client detail with its properties, and the property detail page with
  its access details and change history.

  Deleting a client is refused when the database reports dependent
  records elsewhere (e.g. scheduled jobs) — this module doesn't know or
  care what those dependents are, only that the delete was rejected.

  ## Routes

    * `/clients/:id` (`:show`) and `/clients/:id/edit` (`:edit`) — the
      client and its properties.
    * `/clients/:id/properties/new` (`:new_client_property`) and
      `/properties/new` (`:new_property`) — add a property, with or
      without a preselected client.
    * `/properties/:id` (`:show_property`) and `/properties/:id/edit`
      (`:edit_property`) — a single property's access details and
      change history.

  ## Dependencies

  - `CleanerCrm.Clients`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Clients
  alias CleanerCrm.Clients.Property
  alias CleanerCrmWeb.ClientLive.{FormComponent, PropertyFormComponent}

  @impl true
  def render(%{live_action: action} = assigns) when action in [:show, :edit] do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@client.name}
        <:subtitle :if={!@client.active}>Inactive</:subtitle>
        <:actions>
          <.button navigate={~p"/clients/#{@client}/edit"} class="btn-sm btn-ghost">Edit</.button>
          <.button
            :if={@client.active}
            phx-click={show_confirm("deactivate-client-dialog")}
            data-test="deactivate-client-button"
            class="btn-sm"
          >
            Deactivate
          </.button>
          <.button :if={!@client.active} phx-click="reactivate-client" class="btn-sm">
            Reactivate
          </.button>
          <.button
            phx-click={show_confirm("delete-client-dialog")}
            data-test="delete-client-button"
            class="btn-sm btn-error"
          >
            Delete
          </.button>
        </:actions>
      </.header>

      <.confirm_dialog
        id="deactivate-client-dialog"
        title="Deactivate this client?"
        message="Their upcoming jobs stay on the schedule until cancelled."
        confirm_label="Deactivate"
        confirm_class="btn"
        on_confirm={JS.push("deactivate-client")}
      />

      <.confirm_dialog
        id="delete-client-dialog"
        title="Permanently delete this client?"
        message="This cannot be undone. Deletion is blocked while upcoming jobs exist."
        confirm_label="Delete"
        on_confirm={JS.push("delete-client")}
      />

      <div :if={@live_action == :edit} class="card bg-base-100 border border-base-300 mb-6">
        <div class="card-body">
          <.live_component
            module={FormComponent}
            id="client-form"
            current_scope={@current_scope}
            action={:edit}
            client={@client}
          />
        </div>
      </div>

      <.header>
        Properties
        <:actions>
          <.button navigate={~p"/clients/#{@client}/properties/new"} class="btn-sm">
            <.icon name="hero-plus" class="size-4 mr-1" /> Add Property
          </.button>
        </:actions>
      </.header>

      <p :if={Enum.empty?(@properties)} class="text-center py-8 text-base-content/70">
        No properties yet.
      </p>

      <ul :if={Enum.any?(@properties)} class="list">
        <li :for={property <- @properties} class="list-row">
          <div class="list-col-grow">
            <.link navigate={~p"/properties/#{property}"} class="font-semibold link">
              {property.service_address}
            </.link>
          </div>
        </li>
      </ul>
    </Layouts.app>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>{property_header(@live_action, assigns)}</.header>

      <.live_component
        :if={@live_action in [:new_client_property, :new_property, :edit_property]}
        module={PropertyFormComponent}
        id="property-form"
        current_scope={@current_scope}
        action={property_form_action(@live_action)}
        client={@client}
        property={@property}
      />

      <div :if={@live_action == :show_property} class="space-y-6">
        <p>
          <span class="text-base-content/70">Client:</span>
          <.link
            navigate={~p"/clients/#{@client}"}
            data-test="property-client"
            class="link font-semibold"
          >
            {@client.name}
          </.link>
        </p>

        <div class="card bg-base-100 border border-base-300">
          <div class="card-body space-y-2">
            <p :if={@property.entry_method}>
              <span class="text-base-content/70">Entry method:</span> {@property.entry_method}
            </p>
            <p :if={@property.lockbox_code}>
              <span class="text-base-content/70">Lockbox code:</span> {@property.lockbox_code}
            </p>
            <p :if={@property.alarm_code}>
              <span class="text-base-content/70">Alarm code:</span> {@property.alarm_code}
            </p>
            <p :if={@property.parking_notes}>
              <span class="text-base-content/70">Parking notes:</span> {@property.parking_notes}
            </p>
            <p :if={@property.pet_notes}>
              <span class="text-base-content/70">Pet notes:</span> {@property.pet_notes}
            </p>
            <p :if={@property.emergency_contact_name}>
              <span class="text-base-content/70">Emergency contact:</span>
              {@property.emergency_contact_name} {@property.emergency_contact_phone}
            </p>
          </div>
        </div>

        <div class="flex justify-end">
          <.button navigate={~p"/properties/#{@property}/edit"} class="btn-sm">
            Edit Property
          </.button>
        </div>

        <div>
          <.header>Access Change History</.header>

          <p :if={Enum.empty?(@audit_entries)} class="text-base-content/70">
            No changes recorded yet.
          </p>

          <ul :if={Enum.any?(@audit_entries)} class="list">
            <li
              :for={entry <- @audit_entries}
              data-test="audit-entry"
              data-timestamp={DateTime.to_iso8601(entry.inserted_at)}
              class="list-row"
            >
              <div class="list-col-grow">
                <p>
                  <span class="font-semibold">{entry.actor && entry.actor.email}</span>
                  changed {changed_fields_text(entry)}
                </p>
                <p class="text-sm text-base-content/70">
                  {DateTime.to_iso8601(entry.inserted_at)}
                </p>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    client = Clients.get_client!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, client.name)
    |> assign(:client, client)
    |> assign(:properties, Clients.list_properties(socket.assigns.current_scope, client))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket = apply_action(socket, :show, %{"id" => id})
    assign(socket, :page_title, "Edit #{socket.assigns.client.name}")
  end

  defp apply_action(socket, :new_client_property, %{"id" => id}) do
    client = Clients.get_client!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "New Property")
    |> assign(:client, client)
    |> assign(:property, %Property{})
  end

  defp apply_action(socket, :new_property, _params) do
    socket
    |> assign(:page_title, "New Property")
    |> assign(:client, nil)
    |> assign(:property, %Property{})
  end

  defp apply_action(socket, :show_property, %{"id" => id}) do
    property = Clients.get_property!(socket.assigns.current_scope, id)
    client = Clients.get_client!(socket.assigns.current_scope, property.client_id)

    socket
    |> assign(:page_title, property.service_address)
    |> assign(:property, property)
    |> assign(:client, client)
    |> assign(
      :audit_entries,
      Clients.list_property_audit_entries(socket.assigns.current_scope, property)
    )
  end

  defp apply_action(socket, :edit_property, %{"id" => id}) do
    property = Clients.get_property!(socket.assigns.current_scope, id)
    client = Clients.get_client!(socket.assigns.current_scope, property.client_id)

    socket
    |> assign(:page_title, "Edit Property")
    |> assign(:property, property)
    |> assign(:client, client)
  end

  @impl true
  def handle_event("deactivate-client", _params, socket) do
    {:ok, client} = Clients.deactivate_client(socket.assigns.current_scope, socket.assigns.client)
    {:noreply, assign(socket, :client, client)}
  end

  def handle_event("reactivate-client", _params, socket) do
    {:ok, client} = Clients.reactivate_client(socket.assigns.current_scope, socket.assigns.client)
    {:noreply, assign(socket, :client, client)}
  end

  def handle_event("delete-client", _params, socket) do
    case Clients.delete_client(socket.assigns.current_scope, socket.assigns.client) do
      {:ok, _client} ->
        {:noreply,
         socket
         |> put_flash(:info, "Client deleted successfully")
         |> push_navigate(to: ~p"/clients")}

      {:error, :has_upcoming_jobs} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "This client has upcoming jobs. Please deactivate it or remove the upcoming jobs before deleting."
         )}
    end
  end

  @impl true
  def handle_info({PropertyFormComponent, {:saved, property}}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/properties/#{property}")}
  end

  defp property_header(:new_client_property, %{client: client}),
    do: "New Property for #{client.name}"

  defp property_header(:new_property, _assigns), do: "New Property"

  defp property_header(:edit_property, %{property: property}),
    do: "Edit #{property.service_address}"

  defp property_header(:show_property, %{property: property}), do: property.service_address

  defp property_form_action(:edit_property), do: :edit
  defp property_form_action(_), do: :new

  defp changed_fields_text(%{new_value: %{"changed_fields" => fields}}) when is_list(fields) do
    fields
    |> Enum.map(&String.replace(&1, "_", " "))
    |> Enum.join(", ")
  end

  defp changed_fields_text(_entry), do: "access details"
end
