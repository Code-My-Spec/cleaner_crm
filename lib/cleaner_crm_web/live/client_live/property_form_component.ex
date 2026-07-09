defmodule CleanerCrmWeb.ClientLive.PropertyFormComponent do
  @moduledoc """
  Create/edit a property with its access details (entry method,
  lockbox/alarm codes, parking and pet notes, emergency contact).

  Every property belongs to exactly one client. When the host supplies
  `client`, the client is fixed (e.g. adding a property from a client's
  own page) and no picker is shown. When `client` is `nil`, the form
  renders a client picker and requires a selection.

  ## Assigns

  | Assign          | Type                    | Required | Description                                             |
  |-----------------|-------------------------|----------|----------------------------------------------------------|
  | id              | string                  | yes      | LiveComponent DOM id                                     |
  | current_scope   | `Scope.t()`             | yes      | caller scope, used for all context calls                 |
  | action          | `:new \\| :edit`        | yes      | which mode the form is in                                |
  | property        | `Property.t()`          | yes      | `%Property{}` (blank for `:new`, loaded for `:edit`)      |
  | client          | `Client.t() \\| nil`    | yes      | preselected client, or `nil` to show the picker           |

  On successful save, sends `{__MODULE__, {:saved, property}}` to the
  parent LiveView, which decides where to navigate next.

  ## Dependencies

  - `CleanerCrm.Clients`
  """

  use CleanerCrmWeb, :live_component

  alias CleanerCrm.Clients
  alias CleanerCrm.Clients.Client

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.header>
        {form_title(@action)}
        <:subtitle>Properties carry the access details every job brief inherits.</:subtitle>
      </.header>

      <.form
        for={@form}
        id={"#{@id}-form"}
        data-test="property-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div :if={is_nil(@client)} class="fieldset mb-2">
          <label for={@form[:client_id].id}>
            <span class="label mb-1">Client</span>
            <select
              id={@form[:client_id].id}
              name={@form[:client_id].name}
              class={["w-full select", @form[:client_id].errors != [] && "select-error"]}
            >
              <option value="">Select a client</option>
              {Phoenix.HTML.Form.options_for_select(
                Enum.map(@clients, &{&1.name, &1.id}),
                @form[:client_id].value
              )}
            </select>
          </label>
          <p
            :for={msg <- field_errors(@form[:client_id])}
            data-test="client-error"
            class="mt-1.5 flex gap-2 items-center text-sm text-error"
          >
            <.icon name="hero-exclamation-circle" class="size-5" />{msg}
          </p>
        </div>

        <div class="fieldset mb-2">
          <label for={@form[:service_address].id}>
            <span class="label mb-1">Service Address</span>
            <input
              type="text"
              id={@form[:service_address].id}
              name={@form[:service_address].name}
              value={Phoenix.HTML.Form.normalize_value("text", @form[:service_address].value)}
              class={["w-full input", @form[:service_address].errors != [] && "input-error"]}
            />
          </label>
          <p
            :for={msg <- field_errors(@form[:service_address])}
            data-test="service-address-error"
            class="mt-1.5 flex gap-2 items-center text-sm text-error"
          >
            <.icon name="hero-exclamation-circle" class="size-5" />{msg}
          </p>
        </div>

        <.input field={@form[:entry_method]} type="text" label="Entry Method" />
        <.input field={@form[:lockbox_code]} type="text" label="Lockbox Code" />
        <.input field={@form[:alarm_code]} type="text" label="Alarm Code" />
        <.input field={@form[:parking_notes]} type="textarea" label="Parking Notes" />
        <.input field={@form[:pet_notes]} type="textarea" label="Pet Notes" />
        <.input
          field={@form[:client_preferences]}
          type="textarea"
          label="Client Preferences"
        />
        <.input field={@form[:emergency_contact_name]} type="text" label="Emergency Contact Name" />
        <.input
          field={@form[:emergency_contact_phone]}
          type="text"
          label="Emergency Contact Phone"
        />

        <footer>
          <.button phx-disable-with="Saving...">Save Property</.button>
        </footer>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{property: property, client: client} = assigns, socket) do
    changeset = build_changeset(assigns.current_scope, property, client)
    clients = list_pickable_clients(assigns.current_scope, client)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:clients, clients)
     |> assign(:form, to_form(changeset))}
  end

  defp build_changeset(scope, property, nil), do: Clients.change_property(scope, property)

  defp build_changeset(scope, property, %Client{} = client),
    do: Clients.change_property(scope, property, %{"client_id" => client.id})

  defp list_pickable_clients(_scope, %Client{}), do: []
  defp list_pickable_clients(scope, nil), do: Clients.list_clients(scope)

  @impl true
  def handle_event("validate", %{"property" => property_params}, socket) do
    changeset =
      socket.assigns.current_scope
      |> Clients.change_property(
        socket.assigns.property,
        normalize_params(socket, property_params)
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"property" => property_params}, socket) do
    save_property(socket, socket.assigns.action, normalize_params(socket, property_params))
  end

  # The client is fixed by the host page, not user-editable — always
  # trust the assign over whatever the submitted form happens to carry.
  defp normalize_params(%{assigns: %{client: %Client{} = client}}, params),
    do: Map.put(params, "client_id", client.id)

  defp normalize_params(_socket, params), do: params

  defp save_property(socket, :new, params) do
    case Clients.create_property(socket.assigns.current_scope, params) do
      {:ok, property} ->
        notify_parent({:saved, property})
        {:noreply, navigate_to_property(socket, property)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_property(socket, :edit, params) do
    case Clients.update_property(socket.assigns.current_scope, socket.assigns.property, params) do
      {:ok, property} ->
        notify_parent({:saved, property})
        {:noreply, navigate_to_property(socket, property)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  # Every host routes a saved property to its own page, so the
  # component can own this navigation directly instead of leaving it
  # to a parent's `handle_info` — a round trip through a self-sent
  # message lands one mailbox message after the "save" event's own
  # reply, too late for `Phoenix.LiveViewTest.render_submit/1` to
  # observe. Hosts without a router (e.g. isolated component tests)
  # never call `render_submit` against this path, so the plain
  # `to:` string is safe even though it isn't router-verified there.
  defp navigate_to_property(socket, property) do
    if socket.router do
      push_navigate(socket, to: "/properties/#{property.id}")
    else
      socket
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp field_errors(field) do
    if Phoenix.Component.used_input?(field),
      do: Enum.map(field.errors, &translate_error/1),
      else: []
  end

  defp form_title(:new), do: "New Property"
  defp form_title(:edit), do: "Edit Property"
end
